import Anthropic from "@anthropic-ai/sdk";
import { buildCoachingPrompt, buildGameInitPrompt } from "../prompts/coaching";
import type { GamePhase, TabScreenExtraction } from "../types/game";

function detectGamePhase(minutes: number): GamePhase {
  if (minutes < 12) return "early";
  if (minutes < 22) return "mid";
  return "late";
}

function formatExtraction(extraction: TabScreenExtraction): string {
  const lines: string[] = [];
  lines.push(`Temps: ${extraction.game_time_minutes} minutes`);
  lines.push(`Score: Blue ${extraction.blue_team.kills} - ${extraction.red_team.kills} Red`);

  // Objectives
  const blueObj: string[] = [];
  if (extraction.blue_team.drakes.length) blueObj.push(`Drakes: ${extraction.blue_team.drakes.join(", ")}`);
  if (extraction.blue_team.grubs) blueObj.push(`Grubs: ${extraction.blue_team.grubs}`);
  if (extraction.blue_team.herald) blueObj.push("Herald");
  if (extraction.blue_team.baron) blueObj.push("BARON");
  lines.push(`Blue objectifs: ${blueObj.join(" | ") || "aucun"}`);

  const redObj: string[] = [];
  if (extraction.red_team.drakes.length) redObj.push(`Drakes: ${extraction.red_team.drakes.join(", ")}`);
  if (extraction.red_team.grubs) redObj.push(`Grubs: ${extraction.red_team.grubs}`);
  if (extraction.red_team.herald) redObj.push("Herald");
  if (extraction.red_team.baron) redObj.push("BARON");
  lines.push(`Red objectifs: ${redObj.join(" | ") || "aucun"}`);

  lines.push(`Tours détruites: Blue ${extraction.blue_team.towers_destroyed} - ${extraction.red_team.towers_destroyed} Red`);

  lines.push("\nBLUE TEAM:");
  for (const p of extraction.blue_team.players) {
    lines.push(`  ${p.estimated_role.toUpperCase()} | ${p.champion} (Lv${p.level}) | ${p.name} | ${p.kills}/${p.deaths}/${p.assists} | ${p.cs} CS | Items: ${p.items.filter(Boolean).join(", ") || "none"}`);
  }

  lines.push("\nRED TEAM:");
  for (const p of extraction.red_team.players) {
    lines.push(`  ${p.estimated_role.toUpperCase()} | ${p.champion} (Lv${p.level}) | ${p.name} | ${p.kills}/${p.deaths}/${p.assists} | ${p.cs} CS | Items: ${p.items.filter(Boolean).join(", ") || "none"}`);
  }

  if (extraction.minimap_observations) {
    lines.push(`\nMinimap: ${extraction.minimap_observations}`);
  }
  if (extraction.additional_observations) {
    lines.push(`Notes: ${extraction.additional_observations}`);
  }

  return lines.join("\n");
}

function formatPlayerData(
  players: Map<string, { summoner: { raw: string; rank: string; winRate: number; gamesPlayed: number }; build: { raw: string } }>
): string {
  const lines: string[] = [];
  for (const [name, data] of players) {
    lines.push(`${name}: ${data.summoner.rank} | WR ${data.summoner.winRate}% | ${data.summoner.gamesPlayed} games`);
  }
  return lines.join("\n");
}

function formatBuildRecommendation(
  playerChampion: string,
  players: Map<string, { summoner: { raw: string; rank: string; winRate: number; gamesPlayed: number }; build: { raw: string } }>
): string {
  // Find the build data for the player's champion
  for (const [, data] of players) {
    if (data.build.raw.toLowerCase().includes(playerChampion.toLowerCase())) {
      return data.build.raw;
    }
  }
  return "Aucune donnée de build disponible. Base-toi sur le meta standard.";
}

function summarizePreviousAnalyses(
  analyses: Array<{ extraction: TabScreenExtraction; coaching: string }>
): string {
  if (analyses.length === 0) return "";

  // Keep last 2 analyses in full, summarize older ones
  const lines: string[] = [];

  if (analyses.length > 2) {
    lines.push("=== RÉSUMÉ DES ANALYSES PRÉCÉDENTES ===");
    for (let i = 0; i < analyses.length - 2; i++) {
      const a = analyses[i];
      const time = a.extraction.game_time_minutes;
      const score = `${a.extraction.blue_team.kills}-${a.extraction.red_team.kills}`;
      lines.push(`[${time}min, score ${score}] ${a.coaching.slice(0, 200)}...`);
    }
  }

  lines.push("\n=== ANALYSES RÉCENTES (COMPLÈTES) ===");
  const recent = analyses.slice(-2);
  for (const a of recent) {
    lines.push(`--- Screenshot à ${a.extraction.game_time_minutes}min ---`);
    lines.push(a.coaching);
  }

  return lines.join("\n");
}

export interface CoachStreamCallbacks {
  onText: (text: string) => void;
  onDone: () => void;
  onError: (error: Error) => void;
}

export async function streamGameInitCoaching(
  client: Anthropic,
  params: {
    riotId: string;
    playerChampion: string;
    playerRole: string;
    playerRank: string;
    playerTeam: "blue" | "red";
    extraction: TabScreenExtraction;
    playerDataMap: Map<string, { summoner: { raw: string; rank: string; winRate: number; gamesPlayed: number }; build: { raw: string } }>;
  },
  callbacks: CoachStreamCallbacks
): Promise<void> {
  const prompt = buildGameInitPrompt({
    riotId: params.riotId,
    playerChampion: params.playerChampion,
    playerRole: params.playerRole,
    playerRank: params.playerRank,
    playerTeam: params.playerTeam,
    extraction: formatExtraction(params.extraction),
    playerData: formatPlayerData(params.playerDataMap),
    buildRecommendation: formatBuildRecommendation(params.playerChampion, params.playerDataMap),
  });

  await streamClaudeResponse(client, prompt, callbacks);
}

export async function streamMidGameCoaching(
  client: Anthropic,
  params: {
    riotId: string;
    playerChampion: string;
    playerRole: string;
    playerRank: string;
    playerTeam: "blue" | "red";
    extraction: TabScreenExtraction;
    playerDataMap: Map<string, { summoner: { raw: string; rank: string; winRate: number; gamesPlayed: number }; build: { raw: string } }>;
    previousAnalyses: Array<{ extraction: TabScreenExtraction; coaching: string }>;
  },
  callbacks: CoachStreamCallbacks
): Promise<void> {
  const prompt = buildCoachingPrompt({
    riotId: params.riotId,
    playerChampion: params.playerChampion,
    playerRole: params.playerRole,
    playerRank: params.playerRank,
    playerTeam: params.playerTeam,
    extraction: formatExtraction(params.extraction),
    playerData: formatPlayerData(params.playerDataMap),
    buildRecommendation: formatBuildRecommendation(params.playerChampion, params.playerDataMap),
    previousAnalyses: summarizePreviousAnalyses(params.previousAnalyses),
  });

  await streamClaudeResponse(client, prompt, callbacks);
}

async function streamClaudeResponse(
  client: Anthropic,
  prompt: string,
  callbacks: CoachStreamCallbacks
): Promise<void> {
  const stream = client.messages.stream({
    model: "claude-sonnet-4-5-20250929",
    max_tokens: 2048,
    messages: [{ role: "user", content: prompt }],
  });

  stream.on("text", (text) => callbacks.onText(text));

  // finalMessage() rejects on stream errors, so we wrap it in try/catch.
  // We do NOT use stream.on("error") because finalMessage() already surfaces
  // the error — using both would call onError twice or cause unhandled rejections.
  try {
    await stream.finalMessage();
    callbacks.onDone();
  } catch (error) {
    callbacks.onError(error instanceof Error ? error : new Error(String(error)));
  }
}

export { detectGamePhase, formatExtraction, formatPlayerData, summarizePreviousAnalyses };
