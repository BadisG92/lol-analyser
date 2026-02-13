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

  // Read image as base64
  const imageBuffer = await imageFile.arrayBuffer();
  const imageBase64 = btoa(
    String.fromCharCode(...new Uint8Array(imageBuffer))
  );
  const mediaType = imageFile.type as "image/jpeg" | "image/png" | "image/webp";

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
          send("extraction", extraction);

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
          const session: GameSession = {
            id: sessionId,
            riot_id: riotId,
            region: region as GameSession["region"],
            player_team: playerInfo.team,
            player_role: playerInfo.role,
            player_champion: playerInfo.champion,
            players_blue: [],
            players_red: [],
            analyses: [],
            created_at: Date.now(),
          };

          // Step 5: Stream coaching
          send("status", { step: "coaching", message: "Le coach analyse la game..." });

          const playerRank = playerDataMap.get(playerInfo.name)?.summoner.rank ?? "Gold";
          let fullCoaching = "";

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
                send("error", { message: error.message });
              },
            }
          );

          // Step 6: Save session with first analysis
          const analysis: ScreenshotAnalysis = {
            id: crypto.randomUUID(),
            timestamp: Date.now(),
            extraction,
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

  const session = await getSession(c.env.CACHE, sessionId);
  if (!session) {
    return c.json({ error: "Game session not found" }, 404);
  }

  const imageBuffer = await imageFile.arrayBuffer();
  const imageBase64 = btoa(
    String.fromCharCode(...new Uint8Array(imageBuffer))
  );
  const mediaType = imageFile.type as "image/jpeg" | "image/png" | "image/webp";

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
          send("extraction", extraction);

          // Step 2: Rebuild player data map from session
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

          // For mid-game, we don't re-fetch OP.GG — use cached data from init
          // Build a minimal map from what we have
          const playerDataMap = new Map<string, {
            summoner: { raw: string; rank: string; winRate: number; gamesPlayed: number };
            build: { raw: string };
          }>();
          for (const p of allPlayers) {
            playerDataMap.set(p.name, {
              summoner: { raw: "", rank: "Unknown", winRate: 50, gamesPlayed: 0 },
              build: { raw: "" },
            });
          }

          // Step 3: Stream coaching with context
          send("status", { step: "coaching", message: "Le coach analyse..." });

          const previousAnalyses = session.analyses.map((a) => ({
            extraction: a.extraction,
            coaching: a.coaching,
          }));

          let fullCoaching = "";

          await streamMidGameCoaching(
            anthropic,
            {
              riotId: session.riot_id,
              playerChampion: session.player_champion,
              playerRole: session.player_role,
              playerRank: "Gold", // TODO: persist from init
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
                send("error", { message: error.message });
              },
            }
          );

          // Step 4: Save analysis
          const analysis: ScreenshotAnalysis = {
            id: crypto.randomUUID(),
            timestamp: Date.now(),
            extraction,
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
  const riotIdLower = riotId.toLowerCase().replace("#", "");

  // Try to find exact or partial match in both teams
  for (const player of extraction.blue_team.players) {
    const nameLower = player.name.toLowerCase().replace("#", "");
    if (nameLower.includes(riotIdLower) || riotIdLower.includes(nameLower)) {
      return {
        name: player.name,
        champion: player.champion,
        role: player.estimated_role,
        team: "blue",
      };
    }
  }
  for (const player of extraction.red_team.players) {
    const nameLower = player.name.toLowerCase().replace("#", "");
    if (nameLower.includes(riotIdLower) || riotIdLower.includes(nameLower)) {
      return {
        name: player.name,
        champion: player.champion,
        role: player.estimated_role,
        team: "red",
      };
    }
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

export default game;
