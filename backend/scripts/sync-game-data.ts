#!/usr/bin/env npx tsx
/**
 * Sync Game Data from DDragon
 *
 * Fetches the latest patch data from Riot's Data Dragon CDN and prints
 * a summary. Use this to verify/update the static references in
 * `src/data/items.ts` and `src/data/champions.ts`.
 *
 * Usage:
 *   npx tsx scripts/sync-game-data.ts
 *   npx tsx scripts/sync-game-data.ts --patch 15.3.1
 */

const DDRAGON_BASE = "https://ddragon.leagueoflegends.com";

interface DDragonItem {
  name: string;
  gold: { total: number; base: number; purchasable: boolean; sell: number };
  description: string;
  plaintext: string;
  tags: string[];
  stats: Record<string, number>;
  into?: string[];
  from?: string[];
  maps: Record<string, boolean>;
}

interface DDragonChampion {
  id: string;
  key: string;
  name: string;
  title: string;
  tags: string[];
  info: { attack: number; defense: number; magic: number; difficulty: number };
}

async function main() {
  const patchArg = process.argv.find((a) => a.startsWith("--patch="));
  let patch: string;

  if (patchArg) {
    patch = patchArg.split("=")[1];
  } else {
    console.log("Fetching latest patch version...");
    const resp = await fetch(`${DDRAGON_BASE}/api/versions.json`);
    const versions = (await resp.json()) as string[];
    patch = versions[0];
  }

  console.log(`\nPatch: ${patch}\n`);

  // ── Fetch Items ──
  console.log("Fetching items...");
  const itemsResp = await fetch(
    `${DDRAGON_BASE}/cdn/${patch}/data/en_US/item.json`
  );
  const itemsData = (await itemsResp.json()) as { data: Record<string, DDragonItem> };

  // Filter: only items available on Summoner's Rift (map 11), purchasable, and cost >= 400
  const items = Object.entries(itemsData.data)
    .filter(([, item]) => item.maps["11"] && item.gold.purchasable && item.gold.total >= 400)
    .sort((a, b) => b[1].gold.total - a[1].gold.total);

  console.log(`Total items on SR: ${items.length}\n`);

  // Group by tags
  const tagGroups = new Map<string, Array<[string, DDragonItem]>>();
  for (const entry of items) {
    const tags = entry[1].tags.length > 0 ? entry[1].tags : ["Other"];
    for (const tag of tags) {
      if (!tagGroups.has(tag)) tagGroups.set(tag, []);
      tagGroups.get(tag)!.push(entry);
    }
  }

  for (const [tag, groupItems] of [...tagGroups.entries()].sort()) {
    console.log(`\n── ${tag} (${groupItems.length} items) ──`);
    for (const [id, item] of groupItems.slice(0, 10)) {
      console.log(`  [${id}] ${item.name} (${item.gold.total}g) - ${item.plaintext || "no description"}`);
    }
    if (groupItems.length > 10) {
      console.log(`  ... and ${groupItems.length - 10} more`);
    }
  }

  // ── Fetch Champions ──
  console.log("\n\nFetching champions...");
  const champsResp = await fetch(
    `${DDRAGON_BASE}/cdn/${patch}/data/en_US/champion.json`
  );
  const champsData = (await champsResp.json()) as { data: Record<string, DDragonChampion> };

  const champions = Object.values(champsData.data).sort((a, b) =>
    a.name.localeCompare(b.name)
  );

  console.log(`Total champions: ${champions.length}\n`);

  // Group by primary tag
  const tagChamps = new Map<string, DDragonChampion[]>();
  for (const champ of champions) {
    const tag = champ.tags[0] || "Other";
    if (!tagChamps.has(tag)) tagChamps.set(tag, []);
    tagChamps.get(tag)!.push(champ);
  }

  for (const [tag, group] of [...tagChamps.entries()].sort()) {
    console.log(`\n── ${tag} (${group.length} champions) ──`);
    for (const champ of group) {
      console.log(`  ${champ.id}: ${champ.name} [${champ.tags.join(", ")}]`);
    }
  }

  // ── Summary ──
  console.log(`\n\n═══════════════════════════════════════`);
  console.log(`SUMMARY — Patch ${patch}`);
  console.log(`═══════════════════════════════════════`);
  console.log(`Items on Summoner's Rift: ${items.length}`);
  console.log(`Champions: ${champions.length}`);
  console.log(`\nCompare with src/data/items.ts and src/data/champions.ts`);
  console.log(`and update the static lists if new items/champions were added.`);
}

main().catch(console.error);
