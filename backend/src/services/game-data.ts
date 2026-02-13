/**
 * DDragon / Community Dragon — Static game data
 * Cached in KV with 24h TTL (only changes on patch days)
 */

const DDRAGON_BASE = "https://ddragon.leagueoflegends.com";

interface PatchVersionCache {
  version: string;
  fetchedAt: number;
}

export async function getCurrentPatch(cache?: KVNamespace): Promise<string> {
  if (cache) {
    const cached = await cache.get<PatchVersionCache>("ddragon:version", "json");
    if (cached && Date.now() - cached.fetchedAt < 6 * 3600 * 1000) {
      return cached.version;
    }
  }

  const resp = await fetch(`${DDRAGON_BASE}/api/versions.json`);
  const versions = (await resp.json()) as string[];
  const version = versions[0];

  if (cache) {
    await cache.put(
      "ddragon:version",
      JSON.stringify({ version, fetchedAt: Date.now() }),
      { expirationTtl: 86400 }
    );
  }

  return version;
}

export interface ItemData {
  id: string;
  name: string;
  gold: { total: number; base: number };
  description: string;
  stats: Record<string, number>;
}

export async function getItems(
  cache?: KVNamespace
): Promise<Record<string, ItemData>> {
  if (cache) {
    const cached = await cache.get<Record<string, ItemData>>("ddragon:items", "json");
    if (cached) return cached;
  }

  const version = await getCurrentPatch(cache);
  const resp = await fetch(
    `${DDRAGON_BASE}/cdn/${version}/data/en_US/item.json`
  );
  const data = (await resp.json()) as { data: Record<string, ItemData> };

  if (cache) {
    await cache.put("ddragon:items", JSON.stringify(data.data), {
      expirationTtl: 86400,
    });
  }

  return data.data;
}

export interface ChampionData {
  id: string;
  key: string;
  name: string;
  title: string;
  tags: string[];
}

export async function getChampions(
  cache?: KVNamespace
): Promise<Record<string, ChampionData>> {
  if (cache) {
    const cached = await cache.get<Record<string, ChampionData>>(
      "ddragon:champions",
      "json"
    );
    if (cached) return cached;
  }

  const version = await getCurrentPatch(cache);
  const resp = await fetch(
    `${DDRAGON_BASE}/cdn/${version}/data/en_US/champion.json`
  );
  const data = (await resp.json()) as { data: Record<string, ChampionData> };

  if (cache) {
    await cache.put("ddragon:champions", JSON.stringify(data.data), {
      expirationTtl: 86400,
    });
  }

  return data.data;
}

export async function getSummonerSpells(
  cache?: KVNamespace
): Promise<Record<string, { name: string; description: string }>> {
  if (cache) {
    const cached = await cache.get("ddragon:spells", "json");
    if (cached) return cached as Record<string, { name: string; description: string }>;
  }

  const version = await getCurrentPatch(cache);
  const resp = await fetch(
    `${DDRAGON_BASE}/cdn/${version}/data/en_US/summoner.json`
  );
  const data = (await resp.json()) as {
    data: Record<string, { name: string; description: string }>;
  };

  if (cache) {
    await cache.put("ddragon:spells", JSON.stringify(data.data), {
      expirationTtl: 86400,
    });
  }

  return data.data;
}
