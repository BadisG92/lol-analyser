/**
 * Quick test: validates that extraction + coaching pipeline works
 * Run: npx tsx test/test-extraction.ts <path-to-tab-screenshot>
 *
 * Requires: ANTHROPIC_API_KEY env var
 */

import Anthropic from "@anthropic-ai/sdk";
import { readFileSync } from "fs";
import { EXTRACTION_PROMPT } from "../src/prompts/extraction";
import { buildGameInitPrompt } from "../src/prompts/coaching";

async function main() {
  const imagePath = process.argv[2];

  if (!imagePath) {
    console.log("Usage: npx tsx test/test-extraction.ts <screenshot.jpg>");
    console.log("\nRunning with mock data instead...\n");
    await testWithMockData();
    return;
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    console.error("Set ANTHROPIC_API_KEY env var");
    process.exit(1);
  }

  const client = new Anthropic({ apiKey });
  const imageBuffer = readFileSync(imagePath);
  const imageBase64 = imageBuffer.toString("base64");
  const ext = imagePath.toLowerCase().endsWith(".png") ? "image/png" : "image/jpeg";

  console.log("=== STEP 1: TAB Screen Extraction (Haiku) ===\n");

  const extractionResp = await client.messages.create({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 2048,
    messages: [
      {
        role: "user",
        content: [
          { type: "image", source: { type: "base64", media_type: ext, data: imageBase64 } },
          { type: "text", text: EXTRACTION_PROMPT },
        ],
      },
    ],
  });

  const extractionText = extractionResp.content[0].type === "text" ? extractionResp.content[0].text : "";
  console.log("Extraction result:");
  console.log(extractionText);

  const extraction = JSON.parse(
    extractionText.replace(/^```(?:json)?\s*/, "").replace(/\s*```$/, "")
  );

  console.log("\n=== STEP 2: Coaching (Sonnet) ===\n");

  const prompt = buildGameInitPrompt({
    riotId: "TestPlayer#EUW",
    playerChampion: extraction.blue_team?.players?.[0]?.champion ?? "Unknown",
    playerRole: extraction.blue_team?.players?.[0]?.estimated_role ?? "mid",
    playerRank: "Gold 2",
    playerTeam: "blue",
    extraction: JSON.stringify(extraction, null, 2),
    playerData: "Pas de données OP.GG (test local)",
    buildRecommendation: "Pas de données build (test local)",
  });

  const coachingStream = client.messages.stream({
    model: "claude-sonnet-4-5-20250929",
    max_tokens: 2048,
    messages: [{ role: "user", content: prompt }],
  });

  process.stdout.write("Coaching:\n");
  coachingStream.on("text", (text) => process.stdout.write(text));

  await coachingStream.finalMessage();
  console.log("\n\n=== DONE ===");

  // Print cost estimate
  const extractTokens = extractionResp.usage;
  console.log(`\nExtraction tokens: ${extractTokens.input_tokens} in / ${extractTokens.output_tokens} out`);
}

async function testWithMockData() {
  console.log("=== Mock Test: Coaching Prompt Generation ===\n");

  const prompt = buildGameInitPrompt({
    riotId: "xKairo#EUW",
    playerChampion: "Jinx",
    playerRole: "adc",
    playerRank: "Gold 2",
    playerTeam: "blue",
    extraction: JSON.stringify({
      game_time_minutes: 0,
      blue_team: {
        kills: 0, towers_destroyed: 0, drakes: [], grubs: 0, herald: false, baron: false,
        players: [
          { name: "TopDiff#EUW", champion: "Ornn", level: 1, kills: 0, deaths: 0, assists: 0, cs: 0, items: ["Doran's Shield"], summoner_spells: ["Flash", "Teleport"], estimated_role: "top" },
          { name: "JglKing#EUW", champion: "Lee Sin", level: 1, kills: 0, deaths: 0, assists: 0, cs: 0, items: ["Gustwalker Hatchling"], summoner_spells: ["Flash", "Smite"], estimated_role: "jungle" },
          { name: "MidGap#EUW", champion: "Syndra", level: 1, kills: 0, deaths: 0, assists: 0, cs: 0, items: ["Doran's Ring"], summoner_spells: ["Flash", "Ignite"], estimated_role: "mid" },
          { name: "xKairo#EUW", champion: "Jinx", level: 1, kills: 0, deaths: 0, assists: 0, cs: 0, items: ["Doran's Blade"], summoner_spells: ["Flash", "Heal"], estimated_role: "adc" },
          { name: "SuppDiff#EUW", champion: "Thresh", level: 1, kills: 0, deaths: 0, assists: 0, cs: 0, items: ["Relic Shield"], summoner_spells: ["Flash", "Ignite"], estimated_role: "support" },
        ]
      },
      red_team: {
        kills: 0, towers_destroyed: 0, drakes: [], grubs: 0, herald: false, baron: false,
        players: [
          { name: "Enemy1#EUW", champion: "Gnar", level: 1, kills: 0, deaths: 0, assists: 0, cs: 0, items: ["Doran's Blade"], summoner_spells: ["Flash", "Teleport"], estimated_role: "top" },
          { name: "Enemy2#EUW", champion: "Viego", level: 1, kills: 0, deaths: 0, assists: 0, cs: 0, items: ["Gustwalker Hatchling"], summoner_spells: ["Flash", "Smite"], estimated_role: "jungle" },
          { name: "Enemy3#EUW", champion: "Ahri", level: 1, kills: 0, deaths: 0, assists: 0, cs: 0, items: ["Doran's Ring"], summoner_spells: ["Flash", "Ignite"], estimated_role: "mid" },
          { name: "Enemy4#EUW", champion: "Kai'Sa", level: 1, kills: 0, deaths: 0, assists: 0, cs: 0, items: ["Doran's Blade"], summoner_spells: ["Flash", "Heal"], estimated_role: "adc" },
          { name: "Enemy5#EUW", champion: "Nautilus", level: 1, kills: 0, deaths: 0, assists: 0, cs: 0, items: ["Relic Shield"], summoner_spells: ["Flash", "Ignite"], estimated_role: "support" },
        ]
      },
      minimap_observations: "",
      additional_observations: "Loading screen"
    }, null, 2),
    playerData: `xKairo#EUW: Gold 2 | WR 54% | 120 games (Jinx main, 65% WR sur 45 games)
TopDiff#EUW: Gold 3 | WR 51% | 200 games
JglKing#EUW: Gold 1 | WR 53% | 180 games
MidGap#EUW: Silver 1 | WR 49% | 90 games (possible autofill mid)
SuppDiff#EUW: Gold 4 | WR 52% | 150 games
Enemy1#EUW: Gold 2 | WR 50% | 160 games
Enemy2#EUW: Plat 4 | WR 55% | 200 games (ATTENTION: smurf potentiel)
Enemy3#EUW: Gold 1 | WR 53% | 170 games (Ahri OTP, 58% WR)
Enemy4#EUW: Gold 3 | WR 48% | 130 games (lose streak: 2W 8L last 10)
Enemy5#EUW: Gold 4 | WR 51% | 140 games`,
    buildRecommendation: `Jinx ADC (Patch 25.3) - OP.GG Recommended:
Build: Kraken Slayer → Phantom Dancer → Infinity Edge → Lord Dominik's → Bloodthirster
Boots: Berserker's Greaves (after Noonquiver)
Runes: Lethal Tempo, Presence of Mind, Alacrity, Coup de Grace | Absolute Focus, Gathering Storm
Skill Order: Q > W > E (max Q first)
VS Kai'Sa: Jinx outscales hard. Play safe 1-6, poke with W. Power spike at 2 items.`,
  });

  console.log("Generated prompt length:", prompt.length, "chars (~", Math.ceil(prompt.length / 4), "tokens)\n");
  console.log("--- PROMPT PREVIEW (first 500 chars) ---");
  console.log(prompt.slice(0, 500));
  console.log("...\n--- END PREVIEW ---");
  console.log("\nTo test with Claude, set ANTHROPIC_API_KEY and provide a screenshot path.");
}

main().catch(console.error);
