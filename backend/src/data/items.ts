/**
 * Static item reference — Season 15 (Patch 15.x)
 *
 * Run `npx tsx scripts/sync-game-data.ts` to refresh from DDragon.
 * Organized by category for the extraction prompt.
 *
 * Only includes COMPLETED items (1000+ gold) that appear on TAB screen.
 * Components (Long Sword, Amplifying Tome, etc.) are listed separately.
 */

export interface ItemRef {
  name: string;
  gold: number;
  category: ItemCategory;
  /** Short visual description to help Vision model identify the icon. */
  visual: string;
}

export type ItemCategory =
  | "ad_crit"
  | "ad_lethality"
  | "ap"
  | "attack_speed"
  | "tank_armor"
  | "tank_mr"
  | "tank_health"
  | "support"
  | "boots"
  | "jungle"
  | "starter"
  | "component";

// ═══════════════════════════════════════
// COMPLETED ITEMS
// ═══════════════════════════════════════

export const ITEMS: ItemRef[] = [
  // ── AD / Crit ──
  { name: "Infinity Edge", gold: 3400, category: "ad_crit", visual: "large blue/gold sword" },
  { name: "Kraken Slayer", gold: 3100, category: "ad_crit", visual: "golden trident crossbow" },
  { name: "Bloodthirster", gold: 3200, category: "ad_crit", visual: "red-bladed greatsword" },
  { name: "Lord Dominik's Regards", gold: 3000, category: "ad_crit", visual: "golden heavy crossbow" },
  { name: "Mortal Reminder", gold: 3000, category: "ad_crit", visual: "golden sword with green hilt" },
  { name: "Navori Quickblades", gold: 3400, category: "ad_crit", visual: "dual silver blades" },
  { name: "Essence Reaver", gold: 2900, category: "ad_crit", visual: "purple/gold sword with gem" },
  { name: "The Collector", gold: 3000, category: "ad_crit", visual: "ornate golden pistol" },
  { name: "Phantom Dancer", gold: 2600, category: "ad_crit", visual: "pair of curved daggers" },
  { name: "Rapid Firecannon", gold: 2500, category: "ad_crit", visual: "golden cannon/crossbow" },
  { name: "Statikk Shiv", gold: 2600, category: "ad_crit", visual: "electrified dagger" },
  { name: "Stormrazor", gold: 2700, category: "ad_crit", visual: "lightning-infused sword" },
  { name: "Runaan's Hurricane", gold: 2600, category: "ad_crit", visual: "green bow with wind effects" },
  { name: "Blade of the Ruined King", gold: 3200, category: "ad_crit", visual: "black sword with red runes" },
  { name: "Wit's End", gold: 2800, category: "attack_speed", visual: "curved purple dagger" },
  { name: "Terminus", gold: 3000, category: "attack_speed", visual: "dual-colored blade (light/dark)" },
  { name: "Guinsoo's Rageblade", gold: 2800, category: "attack_speed", visual: "orange/red curved blade" },

  // ── AD / Lethality ──
  { name: "Youmuu's Ghostblade", gold: 2800, category: "ad_lethality", visual: "ghostly green katana" },
  { name: "Edge of Night", gold: 2800, category: "ad_lethality", visual: "dark purple crescent blade" },
  { name: "Serpent's Fang", gold: 2500, category: "ad_lethality", visual: "blue crystal fang dagger" },
  { name: "Axiom Arc", gold: 3000, category: "ad_lethality", visual: "curved purple energy blade" },
  { name: "Hubris", gold: 3000, category: "ad_lethality", visual: "ornate golden scepter/sword" },
  { name: "Opportunity", gold: 2700, category: "ad_lethality", visual: "shadowy dagger" },
  { name: "Voltaic Cyclosword", gold: 2900, category: "ad_lethality", visual: "electric circular blade" },
  { name: "Profane Hydra", gold: 3300, category: "ad_lethality", visual: "dark three-headed axe" },
  { name: "Eclipse", gold: 2800, category: "ad_lethality", visual: "dark crescent sword with glow" },

  // ── AD / Fighter / Bruiser ──
  { name: "Ravenous Hydra", gold: 3300, category: "ad_crit", visual: "red three-headed axe" },
  { name: "Titanic Hydra", gold: 3300, category: "ad_crit", visual: "teal/green three-headed axe" },
  { name: "Black Cleaver", gold: 3000, category: "ad_crit", visual: "black and red axe" },
  { name: "Trinity Force", gold: 3333, category: "ad_crit", visual: "three-pronged golden weapon" },
  { name: "Spear of Shojin", gold: 3100, category: "ad_crit", visual: "ornate eastern spear" },
  { name: "Death's Dance", gold: 3100, category: "ad_crit", visual: "twin red scythes" },
  { name: "Maw of Malmortius", gold: 2800, category: "ad_crit", visual: "purple jaw-shaped blade" },
  { name: "Sterak's Gage", gold: 3100, category: "ad_crit", visual: "large armored gauntlet" },
  { name: "Hullbreaker", gold: 2800, category: "ad_crit", visual: "heavy anchor/battering ram" },
  { name: "Stridebreaker", gold: 3000, category: "ad_crit", visual: "morning star chain weapon" },
  { name: "Experimental Hexplate", gold: 2800, category: "ad_crit", visual: "hextech chest plate" },
  { name: "Sundered Sky", gold: 3100, category: "ad_crit", visual: "cracked golden sword" },

  // ── AP ──
  { name: "Rabadon's Deathcap", gold: 3600, category: "ap", visual: "large purple wizard hat" },
  { name: "Zhonya's Hourglass", gold: 3250, category: "ap", visual: "golden hourglass" },
  { name: "Void Staff", gold: 2500, category: "ap", visual: "purple void staff with eye" },
  { name: "Banshee's Veil", gold: 3000, category: "ap", visual: "purple circlet/crown" },
  { name: "Lich Bane", gold: 3000, category: "ap", visual: "ghostly green curved blade" },
  { name: "Nashor's Tooth", gold: 3000, category: "ap", visual: "large purple fang/tooth" },
  { name: "Morellonomicon", gold: 2200, category: "ap", visual: "green spell book with skull" },
  { name: "Shadowflame", gold: 3000, category: "ap", visual: "dark purple flame orb" },
  { name: "Stormsurge", gold: 2900, category: "ap", visual: "electric blue crystal orb" },
  { name: "Cryptbloom", gold: 2850, category: "ap", visual: "green crystal flower" },
  { name: "Luden's Companion", gold: 2900, category: "ap", visual: "blue/purple arcane orb" },
  { name: "Rod of Ages", gold: 2600, category: "ap", visual: "purple crystal-topped staff" },
  { name: "Archangel's Staff", gold: 2600, category: "ap", visual: "blue angel wing staff" },
  { name: "Seraph's Embrace", gold: 2600, category: "ap", visual: "glowing blue wing staff (evolved)" },
  { name: "Hextech Rocketbelt", gold: 2500, category: "ap", visual: "hextech belt with rockets" },
  { name: "Malignance", gold: 2700, category: "ap", visual: "dark purple evil tome" },
  { name: "Horizon Focus", gold: 2700, category: "ap", visual: "crystalline eye lens" },
  { name: "Cosmic Drive", gold: 2900, category: "ap", visual: "space/nebula orb" },
  { name: "Riftmaker", gold: 2800, category: "ap", visual: "void-touched purple orb" },
  { name: "Blackfire Torch", gold: 2800, category: "ap", visual: "dark torch with black flame" },

  // ── Tank / Armor ──
  { name: "Sunfire Aegis", gold: 2700, category: "tank_armor", visual: "flaming red/orange shield" },
  { name: "Hollow Radiance", gold: 2800, category: "tank_armor", visual: "glowing teal shield" },
  { name: "Iceborn Gauntlet", gold: 2600, category: "tank_armor", visual: "icy blue gauntlet" },
  { name: "Frozen Heart", gold: 2500, category: "tank_armor", visual: "frozen blue heart crystal" },
  { name: "Randuin's Omen", gold: 2700, category: "tank_armor", visual: "spiked iron shield" },
  { name: "Dead Man's Plate", gold: 2900, category: "tank_armor", visual: "dark iron breastplate" },
  { name: "Thornmail", gold: 2450, category: "tank_armor", visual: "spiked thorny vest" },
  { name: "Jak'Sho, The Protean", gold: 2900, category: "tank_armor", visual: "shifting purple/green shell" },
  { name: "Unending Despair", gold: 2800, category: "tank_armor", visual: "dark chain armor with despair aura" },

  // ── Tank / MR ──
  { name: "Spirit Visage", gold: 2700, category: "tank_mr", visual: "green spectral shield" },
  { name: "Force of Nature", gold: 2700, category: "tank_mr", visual: "glowing green amulet" },
  { name: "Kaenic Rookern", gold: 2700, category: "tank_mr", visual: "golden bird-themed shield" },
  { name: "Abyssal Mask", gold: 2300, category: "tank_mr", visual: "purple void mask" },

  // ── Tank / Health ──
  { name: "Heartsteel", gold: 3000, category: "tank_health", visual: "large red crystal heart" },
  { name: "Warmog's Armor", gold: 3000, category: "tank_health", visual: "organic red armor/heart" },

  // ── Support ──
  { name: "Redemption", gold: 2100, category: "support", visual: "golden cross/star" },
  { name: "Mikael's Blessing", gold: 2100, category: "support", visual: "golden chalice" },
  { name: "Ardent Censer", gold: 2100, category: "support", visual: "golden glowing scepter" },
  { name: "Staff of Flowing Water", gold: 2100, category: "support", visual: "blue water staff" },
  { name: "Locket of the Iron Solari", gold: 2200, category: "support", visual: "golden sun shield/locket" },
  { name: "Knight's Vow", gold: 2200, category: "support", visual: "blue knight's medallion" },
  { name: "Zeke's Convergence", gold: 2200, category: "support", visual: "ice and fire combined item" },
  { name: "Echoes of Helia", gold: 2200, category: "support", visual: "glowing green/white orb" },
  { name: "Dream Maker", gold: 2100, category: "support", visual: "starry blue sleeping eye" },
  { name: "Moonstone Renewer", gold: 2100, category: "support", visual: "glowing white moonstone" },
  { name: "Dawncore", gold: 2700, category: "support", visual: "radiant golden core" },
  { name: "Imperial Mandate", gold: 2200, category: "support", visual: "purple/gold commanding scepter" },
  { name: "Trailblazer", gold: 2200, category: "support", visual: "golden compass/pathfinder" },

  // ── Boots ──
  { name: "Berserker's Greaves", gold: 1100, category: "boots", visual: "red/brown attack speed boots" },
  { name: "Sorcerer's Shoes", gold: 1100, category: "boots", visual: "purple magic pen boots" },
  { name: "Plated Steelcaps", gold: 1100, category: "boots", visual: "silver armored boots" },
  { name: "Mercury's Treads", gold: 1100, category: "boots", visual: "green-winged boots" },
  { name: "Ionian Boots of Lucidity", gold: 900, category: "boots", visual: "blue CDR boots" },
  { name: "Boots of Swiftness", gold: 900, category: "boots", visual: "white winged boots" },
  { name: "Symbiotic Soles", gold: 1000, category: "boots", visual: "organic living boots" },
  { name: "Synchronized Souls", gold: 1100, category: "boots", visual: "connected twin boots" },

  // ── Starter Items ──
  { name: "Doran's Blade", gold: 450, category: "starter", visual: "small red sword" },
  { name: "Doran's Ring", gold: 400, category: "starter", visual: "small purple ring" },
  { name: "Doran's Shield", gold: 450, category: "starter", visual: "small bronze shield" },
  { name: "Long Sword", gold: 350, category: "component", visual: "basic iron sword" },
  { name: "Dark Seal", gold: 350, category: "starter", visual: "dark purple signet" },
  { name: "Tear of the Goddess", gold: 400, category: "component", visual: "blue crystal tear" },
  { name: "Cull", gold: 450, category: "starter", visual: "small silver scythe" },

  // ── Key Components (visible on TAB) ──
  { name: "B.F. Sword", gold: 1300, category: "component", visual: "large blue sword" },
  { name: "Needlessly Large Rod", gold: 1250, category: "component", visual: "long purple staff" },
  { name: "Noonquiver", gold: 1000, category: "component", visual: "golden crossbow" },
  { name: "Pickaxe", gold: 875, category: "component", visual: "brown pickaxe" },
  { name: "Recurve Bow", gold: 1000, category: "component", visual: "green bow" },
  { name: "Serrated Dirk", gold: 1100, category: "component", visual: "dark serrated blade" },
  { name: "Hextech Alternator", gold: 1050, category: "component", visual: "hextech orb" },
  { name: "Sheen", gold: 700, category: "component", visual: "shining golden triangle" },
  { name: "Phage", gold: 1100, category: "component", visual: "red crystal mace" },
  { name: "Zeal", gold: 1050, category: "component", visual: "yellow glowing dagger" },
  { name: "Vampiric Scepter", gold: 900, category: "component", visual: "red-tipped scepter" },
  { name: "Hearthbound Axe", gold: 1000, category: "component", visual: "fiery red axe" },
  { name: "Tiamat", gold: 1200, category: "component", visual: "golden crescent blade" },
  { name: "Oblivion Orb", gold: 800, category: "component", visual: "green glowing orb" },
  { name: "Blasting Wand", gold: 850, category: "component", visual: "purple wand" },
  { name: "Giant's Belt", gold: 900, category: "component", visual: "large brown belt" },
  { name: "Chain Vest", gold: 800, category: "component", visual: "silver chainmail" },
  { name: "Negatron Cloak", gold: 900, category: "component", visual: "blue/purple cloak" },
  { name: "Spectre's Cowl", gold: 1250, category: "component", visual: "ghostly green hood" },
  { name: "Bami's Cinder", gold: 1000, category: "component", visual: "fiery ember" },
  { name: "Kindlegem", gold: 800, category: "component", visual: "red gem/ruby" },
  { name: "Catalyst of Aeons", gold: 1100, category: "component", visual: "purple crystal catalyst" },
  { name: "Kircheis Shard", gold: 700, category: "component", visual: "electric shard" },

  // ── Jungle Items ──
  { name: "Gustwalker Hatchling", gold: 0, category: "jungle", visual: "green pet creature" },
  { name: "Scorchclaw Pup", gold: 0, category: "jungle", visual: "red fire pet creature" },
  { name: "Mosstomper Seedling", gold: 0, category: "jungle", visual: "teal/green plant pet" },

  // ── Wards ──
  { name: "Stealth Ward", gold: 0, category: "component", visual: "green eye ward" },
  { name: "Control Ward", gold: 75, category: "component", visual: "pink/red eye ward" },
  { name: "Oracle Lens", gold: 0, category: "component", visual: "red scanning trinket" },
  { name: "Farsight Alteration", gold: 0, category: "component", visual: "blue eye trinket" },

  // ── Support Starters (upgraded) ──
  { name: "World Atlas", gold: 400, category: "starter", visual: "golden book" },
  { name: "Runic Compass", gold: 400, category: "starter", visual: "blue runic compass" },
  { name: "Bounty of Worlds", gold: 0, category: "support", visual: "golden evolved atlas" },
  { name: "Celestial Opposition", gold: 0, category: "support", visual: "blue evolved compass" },
  { name: "Solstice Sleigh", gold: 0, category: "support", visual: "golden sleigh" },
  { name: "Bloodsong", gold: 0, category: "support", visual: "red musical blade" },
  { name: "Zaz'Zak's Realmspike", gold: 0, category: "support", visual: "void spike" },
];

/** All item names as a flat sorted array. */
export const ITEM_NAMES: string[] = ITEMS.map((i) => i.name).sort();

/**
 * Build a condensed item reference string for the extraction prompt.
 * Groups items by category with visual descriptions.
 */
export function buildItemReferenceForExtraction(): string {
  const groups: Record<string, ItemRef[]> = {};
  for (const item of ITEMS) {
    if (!groups[item.category]) groups[item.category] = [];
    groups[item.category].push(item);
  }

  const categoryLabels: Record<string, string> = {
    ad_crit: "AD / Crit / Fighter",
    ad_lethality: "AD / Lethality (Assassin)",
    ap: "AP (Mage)",
    attack_speed: "Attack Speed / On-Hit",
    tank_armor: "Tank (Armor)",
    tank_mr: "Tank (MR)",
    tank_health: "Tank (Health)",
    support: "Support",
    boots: "Boots",
    jungle: "Jungle Pets",
    starter: "Starter Items",
    component: "Components",
  };

  const lines: string[] = ["RÉFÉRENCE ITEMS (PATCH ACTUEL) :"];
  const displayOrder: ItemCategory[] = [
    "ad_crit", "ad_lethality", "ap", "attack_speed",
    "tank_armor", "tank_mr", "tank_health",
    "support", "boots", "starter", "component",
  ];

  for (const cat of displayOrder) {
    const items = groups[cat];
    if (!items) continue;
    lines.push(`\n[${categoryLabels[cat] ?? cat}]`);
    for (const item of items) {
      lines.push(`- ${item.name} (${item.visual})`);
    }
  }

  return lines.join("\n");
}

/**
 * Build a condensed item name list (no visuals) for coaching context.
 */
export function buildItemListForCoaching(): string {
  const completed = ITEMS.filter(
    (i) => i.category !== "component" && i.category !== "starter" && i.gold >= 1000
  );
  return completed.map((i) => i.name).join(", ");
}
