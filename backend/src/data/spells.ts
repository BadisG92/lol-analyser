/**
 * Summoner Spells reference — Season 15
 *
 * Used for extraction validation and image URL building.
 */

export interface SpellRef {
  name: string;
  key: string;       // DDragon key (e.g., "SummonerFlash")
  cooldown: number;   // Base cooldown in seconds
  visual: string;     // Icon description for extraction
}

export const SUMMONER_SPELLS: SpellRef[] = [
  { name: "Flash", key: "SummonerFlash", cooldown: 300, visual: "yellow lightning bolt on blue" },
  { name: "Ignite", key: "SummonerDot", cooldown: 180, visual: "orange/red flame" },
  { name: "Teleport", key: "SummonerTeleport", cooldown: 360, visual: "purple swirling portal" },
  { name: "Exhaust", key: "SummonerExhaust", cooldown: 210, visual: "purple slow spiral" },
  { name: "Heal", key: "SummonerHeal", cooldown: 240, visual: "green cross/plus" },
  { name: "Ghost", key: "SummonerHaste", cooldown: 210, visual: "blue ghostly trail" },
  { name: "Barrier", key: "SummonerBarrier", cooldown: 180, visual: "orange/gold shield dome" },
  { name: "Cleanse", key: "SummonerBoost", cooldown: 210, visual: "teal/turquoise water splash" },
  { name: "Smite", key: "SummonerSmite", cooldown: 90, visual: "orange/red sword strike" },
];

export const SPELL_NAMES: string[] = SUMMONER_SPELLS.map((s) => s.name);

export function findSpell(name: string): SpellRef | undefined {
  return SUMMONER_SPELLS.find(
    (s) => s.name.toLowerCase() === name.toLowerCase()
  );
}
