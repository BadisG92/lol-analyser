import { Hono } from "hono";
import Anthropic from "@anthropic-ai/sdk";
import type { Env } from "../types/env";
import type { GameSession, Role, ScreenshotAnalysis, TabScreenExtraction } from "../types/game";
import { extractTabScreen } from "../services/vision";
import { fetchAllPlayersData } from "../services/opgg";
import {
  streamGameInitCoaching,
  streamMidGameCoaching,
  detectGamePhase,
} from "../services/coach";
import { saveSession, getSession, addAnalysis, addUserSession } from "../services/cache";
import { championIconUrl, getItemImageUrl, getSpellImageUrl, CURRENT_PATCH } from "../data/ddragon";
import { findChampion } from "../data/champions";

const game = new Hono<{ Bindings: Env }>();

/**
 * POST /game/init
 * First screenshot → extract → fetch player data → stream coaching
 *
 * Accepts: multipart/form-data with image, riot_id, region
 * Returns: SSE stream with extraction, players, coaching events
 */
game.post("/init", async (c) => {
  const formData = await c.req.formData();
  const imageFile = formData.get("image") as File | null;
  const riotId = formData.get("riot_id") as string | null;
  const region = formData.get("region") as string | null;

  if (!imageFile || !riotId || !region) {
    return c.json({ error: "Missing image, riot_id, or region" }, 400);
  }

  // Reject oversized images to prevent Worker OOM (5 MB limit)
  if (imageFile.size > 5 * 1024 * 1024) {
    return c.json({ error: "Image too large (max 5 MB). Use JPEG for smaller file size." }, 413);
  }

  // Read image as base64 (chunk-safe for large images on Workers)
  const imageBuffer = await imageFile.arrayBuffer();
  const imageBase64 = arrayBufferToBase64(imageBuffer);

  // Validate media type before sending to Anthropic
  const validMediaTypes = ["image/jpeg", "image/png", "image/webp"] as const;
  const rawMediaType = imageFile.type;
  const mediaType = validMediaTypes.includes(rawMediaType as typeof validMediaTypes[number])
    ? (rawMediaType as "image/jpeg" | "image/png" | "image/webp")
    : "image/jpeg"; // Default to JPEG for unrecognized types

  const anthropic = new Anthropic({ apiKey: c.env.ANTHROPIC_API_KEY });

  // SSE stream
  return new Response(
    new ReadableStream({
      async start(controller) {
        const encoder = new TextEncoder();
        const send = (event: string, data: unknown) => {
          controller.enqueue(
            encoder.encode(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`)
          );
        };

        try {
          // Step 1: Extract TAB screen
          send("status", { step: "extraction", message: "Analyse du screenshot..." });
          const extraction = await extractTabScreen(anthropic, imageBase64, mediaType);
          send("extraction", enrichExtraction(extraction));

          // Step 2: Identify the player in the game
          const playerInfo = findPlayer(extraction, riotId);
          send("player", playerInfo);

          // Step 3: Fetch player data from OP.GG (all 10 players in parallel)
          send("status", { step: "players", message: "Récupération des données joueurs..." });
          const allPlayers = [
            ...extraction.blue_team.players.map((p) => ({
              name: p.name,
              champion: p.champion,
              role: p.estimated_role,
            })),
            ...extraction.red_team.players.map((p) => ({
              name: p.name,
              champion: p.champion,
              role: p.estimated_role,
            })),
          ];

          const playerDataMap = await fetchAllPlayersData(allPlayers, region);
          send("players_data", {
            count: playerDataMap.size,
            message: `Données récupérées pour ${playerDataMap.size} joueurs`,
          });

          // Step 4: Create game session
          const sessionId = crypto.randomUUID();
          const playerRank = playerDataMap.get(playerInfo.name)?.summoner.rank ?? "Gold";

          // Serialize player data map so mid-game analyses can reuse OP.GG data
          const playerDataSerialized: Record<string, { summoner: { raw: string; rank: string; winRate: number; gamesPlayed: number }; build: { raw: string } }> = {};
          for (const [name, data] of playerDataMap) {
            playerDataSerialized[name] = data;
          }

          const session: GameSession = {
            id: sessionId,
            riot_id: riotId,
            region: region as GameSession["region"],
            player_team: playerInfo.team,
            player_role: playerInfo.role,
            player_champion: playerInfo.champion,
            player_rank: playerRank,
            players_blue: [],
            players_red: [],
            player_data: playerDataSerialized,
            analyses: [],
            created_at: Date.now(),
          };

          // Step 5: Stream coaching
          send("status", { step: "coaching", message: "Le coach analyse la game..." });
          let fullCoaching = "";
          let streamingError = false;

          await streamGameInitCoaching(
            anthropic,
            {
              riotId,
              playerChampion: playerInfo.champion,
              playerRole: playerInfo.role,
              playerRank,
              playerTeam: playerInfo.team,
              extraction,
              playerDataMap,
            },
            {
              onText: (text) => {
                fullCoaching += text;
                send("coaching", { text });
              },
              onDone: () => {},
              onError: (error) => {
                streamingError = true;
                send("error", { message: error.message });
              },
            }
          );

          // If the coaching stream failed, don't save partial data or
          // send a "done" event — the client already received "error".
          if (streamingError) return;

          // Step 6: Save session with first analysis
          // Store the enriched extraction (with DDragon URLs) so the REST API
          // returns data in the same shape the iOS app expects.
          const enrichedData = enrichExtraction(extraction);
          const analysis: ScreenshotAnalysis = {
            id: crypto.randomUUID(),
            timestamp: Date.now(),
            extraction: enrichedData as unknown as TabScreenExtraction,
            coaching: fullCoaching,
            game_phase: detectGamePhase(extraction.game_time_minutes),
          };
          session.analyses.push(analysis);

          await saveSession(c.env.CACHE, session);
          await addUserSession(c.env.CACHE, riotId, sessionId);

          send("done", {
            game_id: sessionId,
            phase: analysis.game_phase,
            game_time: extraction.game_time_minutes,
          });
        } catch (error) {
          const message = error instanceof Error ? error.message : "Unknown error";
          send("error", { message });
        } finally {
          controller.close();
        }
      },
    }),
    {
      headers: {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
        "Access-Control-Allow-Origin": "*",
      },
    }
  );
});

/**
 * POST /game/:id/analyze
 * Subsequent screenshot → extract → coaching with full context
 */
game.post("/:id/analyze", async (c) => {
  const sessionId = c.req.param("id");
  const formData = await c.req.formData();
  const imageFile = formData.get("image") as File | null;

  if (!imageFile) {
    return c.json({ error: "Missing image" }, 400);
  }

  // Reject oversized images to prevent Worker OOM (5 MB limit)
  if (imageFile.size > 5 * 1024 * 1024) {
    return c.json({ error: "Image too large (max 5 MB). Use JPEG for smaller file size." }, 413);
  }

  const session = await getSession(c.env.CACHE, sessionId);
  if (!session) {
    return c.json({ error: "Game session not found" }, 404);
  }

  const imageBuffer = await imageFile.arrayBuffer();
  const imageBase64 = arrayBufferToBase64(imageBuffer);

  // Validate media type before sending to Anthropic
  const validMediaTypes = ["image/jpeg", "image/png", "image/webp"] as const;
  const rawMediaType = imageFile.type;
  const mediaType = validMediaTypes.includes(rawMediaType as typeof validMediaTypes[number])
    ? (rawMediaType as "image/jpeg" | "image/png" | "image/webp")
    : "image/jpeg";

  const anthropic = new Anthropic({ apiKey: c.env.ANTHROPIC_API_KEY });

  return new Response(
    new ReadableStream({
      async start(controller) {
        const encoder = new TextEncoder();
        const send = (event: string, data: unknown) => {
          controller.enqueue(
            encoder.encode(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`)
          );
        };

        try {
          // Step 1: Extract TAB screen
          send("status", { step: "extraction", message: "Analyse du screenshot..." });
          const extraction = await extractTabScreen(anthropic, imageBase64, mediaType);
          send("extraction", enrichExtraction(extraction));

          // Step 2: Rebuild player data map from session's cached OP.GG data
          const playerDataMap = new Map<string, {
            summoner: { raw: string; rank: string; winRate: number; gamesPlayed: number };
            build: { raw: string };
          }>();

          // Restore cached player data from the session (saved during init)
          if (session.player_data) {
            for (const [name, data] of Object.entries(session.player_data)) {
              playerDataMap.set(name, data);
            }
          }

          // Fill in any new/unrecognized players with defaults
          const allPlayers = [
            ...extraction.blue_team.players.map((p) => p.name),
            ...extraction.red_team.players.map((p) => p.name),
          ];
          for (const name of allPlayers) {
            if (!playerDataMap.has(name)) {
              playerDataMap.set(name, {
                summoner: { raw: "", rank: "Unknown", winRate: 50, gamesPlayed: 0 },
                build: { raw: "" },
              });
            }
          }

          // Step 3: Stream coaching with context
          send("status", { step: "coaching", message: "Le coach analyse..." });

          const previousAnalyses = session.analyses.map((a) => ({
            extraction: a.extraction,
            coaching: a.coaching,
          }));

          let fullCoaching = "";
          let streamingError = false;

          await streamMidGameCoaching(
            anthropic,
            {
              riotId: session.riot_id,
              playerChampion: session.player_champion,
              playerRole: session.player_role,
              playerRank: session.player_rank ?? "Gold",
              playerTeam: session.player_team,
              extraction,
              playerDataMap,
              previousAnalyses,
            },
            {
              onText: (text) => {
                fullCoaching += text;
                send("coaching", { text });
              },
              onDone: () => {},
              onError: (error) => {
                streamingError = true;
                send("error", { message: error.message });
              },
            }
          );

          // If the coaching stream failed, don't save partial data or
          // send a "done" event — the client already received "error".
          if (streamingError) return;

          // Step 4: Save analysis (enriched with DDragon URLs)
          const enrichedData = enrichExtraction(extraction);
          const analysis: ScreenshotAnalysis = {
            id: crypto.randomUUID(),
            timestamp: Date.now(),
            extraction: enrichedData as unknown as TabScreenExtraction,
            coaching: fullCoaching,
            game_phase: detectGamePhase(extraction.game_time_minutes),
          };

          await addAnalysis(c.env.CACHE, sessionId, analysis);

          send("done", {
            analysis_id: analysis.id,
            phase: analysis.game_phase,
            game_time: extraction.game_time_minutes,
            total_analyses: session.analyses.length + 1,
          });
        } catch (error) {
          const message = error instanceof Error ? error.message : "Unknown error";
          send("error", { message });
        } finally {
          controller.close();
        }
      },
    }),
    {
      headers: {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
        "Access-Control-Allow-Origin": "*",
      },
    }
  );
});

/**
 * GET /game/:id
 * Retrieve a game session
 */
game.get("/:id", async (c) => {
  const session = await getSession(c.env.CACHE, c.req.param("id"));
  if (!session) {
    return c.json({ error: "Game session not found" }, 404);
  }
  return c.json(session);
});

// ── Helper: find the coachee in the extraction ──

function findPlayer(
  extraction: TabScreenExtraction,
  riotId: string
): { name: string; champion: string; role: Role; team: "blue" | "red" } {
  // Normalize: remove "#" and taglines for matching.
  // Riot ID format: "Name#TAG". OCR may drop the tag or mangle it.
  const normalize = (s: string) => s.toLowerCase().replace(/#/g, " ").trim();
  const riotNorm = normalize(riotId);

  const allPlayers = [
    ...extraction.blue_team.players.map((p) => ({ ...p, team: "blue" as const })),
    ...extraction.red_team.players.map((p) => ({ ...p, team: "red" as const })),
  ];

  // Pass 1: Exact match (after normalization)
  for (const player of allPlayers) {
    if (normalize(player.name) === riotNorm) {
      return {
        name: player.name,
        champion: player.champion,
        role: player.estimated_role,
        team: player.team,
      };
    }
  }

  // Pass 2: One contains the other, but prefer the BEST match (longest overlap).
  // Score by how much of the riotId the name covers + vice versa.
  // Only match if at least 3 characters overlap to avoid matching "A" in "Azir Player".
  type ScoredMatch = { player: (typeof allPlayers)[number]; score: number };
  const MIN_MATCH_LEN = 3;
  const candidates: ScoredMatch[] = [];

  for (const player of allPlayers) {
    const nameNorm = normalize(player.name);
    if (nameNorm.length < MIN_MATCH_LEN && riotNorm.length < MIN_MATCH_LEN) continue;

    if (nameNorm.includes(riotNorm) && riotNorm.length >= MIN_MATCH_LEN) {
      // riotId is fully contained in the player name
      candidates.push({ player, score: riotNorm.length / nameNorm.length });
    } else if (riotNorm.includes(nameNorm) && nameNorm.length >= MIN_MATCH_LEN) {
      // player name is fully contained in the riotId
      candidates.push({ player, score: nameNorm.length / riotNorm.length });
    }
  }

  if (candidates.length > 0) {
    // Pick the best scoring match (closest to 1.0 = most overlap)
    candidates.sort((a, b) => b.score - a.score);
    const best = candidates[0].player;
    return {
      name: best.name,
      champion: best.champion,
      role: best.estimated_role,
      team: best.team,
    };
  }

  // Fallback: return first player of blue team
  const fallback = extraction.blue_team.players[0];
  return {
    name: fallback?.name ?? riotId,
    champion: fallback?.champion ?? "Unknown",
    role: fallback?.estimated_role ?? "mid",
    team: "blue",
  };
}

// ── Helper: ArrayBuffer to base64 without stack overflow ──
// String.fromCharCode(...uint8Array) blows the call stack for images >64KB.
// Process in 8KB chunks to stay safe on Cloudflare Workers.

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  const CHUNK = 8192;
  let binary = "";
  for (let i = 0; i < bytes.length; i += CHUNK) {
    const slice = bytes.subarray(i, Math.min(i + CHUNK, bytes.length));
    binary += String.fromCharCode(...slice);
  }
  return btoa(binary);
}

// ── Helper: enrich extraction with DDragon image URLs ──

interface PlayerWithImages {
  name: string;
  champion: string;
  champion_icon: string;
  level: number;
  kills: number;
  deaths: number;
  assists: number;
  cs: number;
  items: Array<{ name: string | null; icon: string | null }>;
  summoner_spells: Array<{ name: string; icon: string | null }>;
  estimated_role: string;
}

interface EnrichedExtraction {
  patch: string;
  game_time_minutes: number;
  blue_team: {
    kills: number;
    towers_destroyed: number;
    drakes: string[];
    grubs: number;
    herald: boolean;
    baron: boolean;
    players: PlayerWithImages[];
  };
  red_team: {
    kills: number;
    towers_destroyed: number;
    drakes: string[];
    grubs: number;
    herald: boolean;
    baron: boolean;
    players: PlayerWithImages[];
  };
  minimap_observations: string;
  additional_observations: string;
}

function enrichExtraction(extraction: TabScreenExtraction): EnrichedExtraction {
  function enrichPlayers(players: TabScreenExtraction["blue_team"]["players"]): PlayerWithImages[] {
    return players.map((p) => ({
      name: p.name,
      champion: p.champion,
      champion_icon: championIconUrl(findChampion(p.champion)?.id ?? p.champion),
      level: p.level,
      kills: p.kills,
      deaths: p.deaths,
      assists: p.assists,
      cs: p.cs,
      items: p.items.map((itemName) => ({
        name: itemName,
        icon: itemName ? getItemImageUrl(itemName) : null,
      })),
      summoner_spells: p.summoner_spells.map((spellName) => ({
        name: spellName,
        icon: spellName ? getSpellImageUrl(spellName) : null,
      })),
      estimated_role: p.estimated_role,
    }));
  }

  return {
    patch: CURRENT_PATCH,
    game_time_minutes: extraction.game_time_minutes,
    blue_team: {
      ...extraction.blue_team,
      players: enrichPlayers(extraction.blue_team.players),
    },
    red_team: {
      ...extraction.red_team,
      players: enrichPlayers(extraction.red_team.players),
    },
    minimap_observations: extraction.minimap_observations,
    additional_observations: extraction.additional_observations,
  };
}

export default game;
