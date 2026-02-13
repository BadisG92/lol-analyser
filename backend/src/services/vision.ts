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

  // Strip markdown code fences if present
  const jsonStr = text.replace(/^```(?:json)?\s*/, "").replace(/\s*```$/, "");

  const parsed = JSON.parse(jsonStr) as TabScreenExtraction;
  return validateExtraction(parsed);
}

function validateExtraction(data: TabScreenExtraction): TabScreenExtraction {
  if (data.game_time_minutes < 0 || data.game_time_minutes > 90) {
    data.game_time_minutes = 0;
  }

  for (const team of [data.blue_team, data.red_team]) {
    for (const player of team.players) {
      player.kills = Math.max(0, player.kills ?? 0);
      player.deaths = Math.max(0, player.deaths ?? 0);
      player.assists = Math.max(0, player.assists ?? 0);
      player.cs = Math.max(0, Math.min(999, player.cs ?? 0));
      player.level = Math.max(1, Math.min(18, player.level ?? 1));
      if (!player.items) player.items = [];
      if (player.items.length > 7) player.items = player.items.slice(0, 7);
    }
  }

  return data;
}
