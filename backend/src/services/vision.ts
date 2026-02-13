import Anthropic from "@anthropic-ai/sdk";
import { EXTRACTION_PROMPT } from "../prompts/extraction";
import type { TabScreenExtraction } from "../types/game";

export async function extractTabScreen(
  client: Anthropic,
  imageBase64: string,
  mediaType: "image/jpeg" | "image/png" | "image/webp"
): Promise<TabScreenExtraction> {
  const response = await client.messages.create({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 2048,
    messages: [
      {
        role: "user",
        content: [
          {
            type: "image",
            source: { type: "base64", media_type: mediaType, data: imageBase64 },
          },
          { type: "text", text: EXTRACTION_PROMPT },
        ],
      },
    ],
  });

  const text =
    response.content[0].type === "text" ? response.content[0].text : "";

  // Extract JSON robustly: Haiku may wrap JSON in code fences or surrounding text.
  // Strategy: find the outermost { ... } JSON object in the response.
  const jsonStr = extractJsonFromText(text);

  const parsed = JSON.parse(jsonStr) as TabScreenExtraction;
  return validateExtraction(parsed);
}

/**
 * Robustly extract JSON from LLM text that may contain markdown fences,
 * preamble text, or trailing commentary.
 */
function extractJsonFromText(text: string): string {
  // 1. Try stripping markdown code fences (handles ```json ... ``` anywhere)
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  if (fenceMatch) return fenceMatch[1];

  // 2. Find the first '{' and the matching last '}' — the outermost JSON object
  const firstBrace = text.indexOf("{");
  const lastBrace = text.lastIndexOf("}");
  if (firstBrace !== -1 && lastBrace > firstBrace) {
    return text.slice(firstBrace, lastBrace + 1);
  }

  // 3. Last resort: return as-is and let JSON.parse throw a clear error
  return text;
}

function validateExtraction(data: TabScreenExtraction): TabScreenExtraction {
  // Structural validation: must have both teams with players arrays
  if (!data.blue_team?.players || !Array.isArray(data.blue_team.players)) {
    throw new Error("Invalid extraction: missing blue_team.players");
  }
  if (!data.red_team?.players || !Array.isArray(data.red_team.players)) {
    throw new Error("Invalid extraction: missing red_team.players");
  }

  // LoL always has exactly 5 players per team
  if (data.blue_team.players.length !== 5) {
    console.warn(`Extraction: blue_team has ${data.blue_team.players.length} players (expected 5)`);
    if (data.blue_team.players.length === 0) {
      throw new Error("Invalid extraction: blue_team has 0 players");
    }
  }
  if (data.red_team.players.length !== 5) {
    console.warn(`Extraction: red_team has ${data.red_team.players.length} players (expected 5)`);
    if (data.red_team.players.length === 0) {
      throw new Error("Invalid extraction: red_team has 0 players");
    }
  }

  if (data.game_time_minutes == null || data.game_time_minutes < 0 || data.game_time_minutes > 90) {
    data.game_time_minutes = 0;
  }

  // Ensure string fields are never null (AI might return null for missing observations)
  if (!data.minimap_observations) data.minimap_observations = "";
  if (!data.additional_observations) data.additional_observations = "";

  for (const team of [data.blue_team, data.red_team]) {
    if (!team.drakes) team.drakes = [];
    team.drakes = team.drakes.filter((d): d is string => typeof d === "string" && d !== "");
    if (team.towers_destroyed == null) team.towers_destroyed = 0;
    if (team.grubs == null) team.grubs = 0;
    team.kills = Math.max(0, team.kills ?? 0);
    team.herald = !!team.herald;
    team.baron = !!team.baron;
    for (const player of team.players) {
      if (!player.name) player.name = "Unknown";
      if (!player.champion) player.champion = "Unknown";
      if (!player.estimated_role) player.estimated_role = "mid";
      player.kills = Math.max(0, player.kills ?? 0);
      player.deaths = Math.max(0, player.deaths ?? 0);
      player.assists = Math.max(0, player.assists ?? 0);
      player.cs = Math.max(0, Math.min(999, player.cs ?? 0));
      player.level = Math.max(1, Math.min(18, player.level ?? 1));
      if (!player.items) player.items = [];
      player.items = player.items.filter((item): item is string => typeof item === "string" && item !== "");
      if (player.items.length > 7) player.items = player.items.slice(0, 7);
      if (!player.summoner_spells) player.summoner_spells = [];
      player.summoner_spells = player.summoner_spells.filter((s): s is string => typeof s === "string" && s !== "");
    }
  }

  return data;
}
