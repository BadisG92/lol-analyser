/**
 * DDragon CDN image URL builder.
 *
 * All images are served from Riot's free CDN.
 * URLs follow the pattern: https://ddragon.leagueoflegends.com/cdn/{version}/img/{type}/{filename}.png
 *
 * The iOS app loads these via AsyncImage at runtime — no need to store PNGs locally.
 */

const DDRAGON_CDN = "https://ddragon.leagueoflegends.com/cdn";

/** Current patch version — update on new patches or fetch dynamically via game-data.ts */
export const CURRENT_PATCH = "15.3.1";

// ── URL Builders ──

export function championIconUrl(championId: string, patch = CURRENT_PATCH): string {
  return `${DDRAGON_CDN}/${patch}/img/champion/${championId}.png`;
}

export function championSplashUrl(championId: string, skinNum = 0): string {
  return `${DDRAGON_CDN}/img/champion/splash/${championId}_${skinNum}.jpg`;
}

export function championLoadingUrl(championId: string, skinNum = 0): string {
  return `${DDRAGON_CDN}/img/champion/loading/${championId}_${skinNum}.jpg`;
}

export function itemIconUrl(itemId: string | number, patch = CURRENT_PATCH): string {
  return `${DDRAGON_CDN}/${patch}/img/item/${itemId}.png`;
}

export function spellIconUrl(spellKey: string, patch = CURRENT_PATCH): string {
  return `${DDRAGON_CDN}/${patch}/img/spell/${spellKey}.png`;
}

export function profileIconUrl(iconId: number, patch = CURRENT_PATCH): string {
  return `${DDRAGON_CDN}/${patch}/img/profileicon/${iconId}.png`;
}

// ── Item Name → DDragon ID Mapping ──
// Used to convert extracted item names to image URLs

export const ITEM_NAME_TO_ID: Record<string, number> = {
  // AD / Crit
  "Infinity Edge": 3031,
  "Kraken Slayer": 6672,
  "Bloodthirster": 3072,
  "Lord Dominik's Regards": 3036,
  "Mortal Reminder": 3033,
  "Navori Quickblades": 6675,
  "Essence Reaver": 3508,
  "The Collector": 6676,
  "Phantom Dancer": 3046,
  "Rapid Firecannon": 3094,
  "Statikk Shiv": 3087,
  "Stormrazor": 3095,
  "Runaan's Hurricane": 3085,
  "Blade of the Ruined King": 3153,
  "Wit's End": 3091,
  "Terminus": 3302,
  "Guinsoo's Rageblade": 3124,

  // AD / Lethality
  "Youmuu's Ghostblade": 3142,
  "Edge of Night": 3814,
  "Serpent's Fang": 6695,
  "Axiom Arc": 6696,
  "Hubris": 6697,
  "Opportunity": 6699,
  "Voltaic Cyclosword": 6698,
  "Profane Hydra": 6700,
  "Eclipse": 6701,

  // AD / Bruiser
  "Ravenous Hydra": 3074,
  "Titanic Hydra": 3748,
  "Black Cleaver": 3071,
  "Trinity Force": 3078,
  "Spear of Shojin": 3161,
  "Death's Dance": 6333,
  "Maw of Malmortius": 3156,
  "Sterak's Gage": 3053,
  "Hullbreaker": 3181,
  "Stridebreaker": 6631,
  "Experimental Hexplate": 2501,
  "Sundered Sky": 6610,

  // AP
  "Rabadon's Deathcap": 3089,
  "Zhonya's Hourglass": 3157,
  "Void Staff": 3135,
  "Banshee's Veil": 3102,
  "Lich Bane": 3100,
  "Nashor's Tooth": 3115,
  "Morellonomicon": 3165,
  "Shadowflame": 4645,
  "Stormsurge": 4646,
  "Cryptbloom": 4647,
  "Luden's Companion": 6655,
  "Rod of Ages": 6657,
  "Archangel's Staff": 3003,
  "Seraph's Embrace": 3040,
  "Hextech Rocketbelt": 3152,
  "Malignance": 3118,
  "Horizon Focus": 4628,
  "Cosmic Drive": 4629,
  "Riftmaker": 4633,
  "Blackfire Torch": 4648,

  // Tank / Armor
  "Sunfire Aegis": 3068,
  "Hollow Radiance": 6664,
  "Iceborn Gauntlet": 3025,
  "Frozen Heart": 3110,
  "Randuin's Omen": 3143,
  "Dead Man's Plate": 3742,
  "Thornmail": 3075,
  "Jak'Sho, The Protean": 6665,
  "Unending Despair": 2502,

  // Tank / MR
  "Spirit Visage": 3065,
  "Force of Nature": 4401,
  "Kaenic Rookern": 4403,
  "Abyssal Mask": 3001,

  // Tank / Health
  "Heartsteel": 3084,
  "Warmog's Armor": 3083,

  // Support
  "Redemption": 3107,
  "Mikael's Blessing": 3222,
  "Ardent Censer": 3504,
  "Staff of Flowing Water": 3505,
  "Locket of the Iron Solari": 3190,
  "Knight's Vow": 3109,
  "Zeke's Convergence": 3050,
  "Echoes of Helia": 6620,
  "Dream Maker": 3870,
  "Moonstone Renewer": 6617,
  "Dawncore": 6621,
  "Imperial Mandate": 4005,
  "Trailblazer": 3876,
  "Celestial Opposition": 3869,
  "Bloodsong": 3877,
  "Zaz'Zak's Realmspike": 3871,
  "Solstice Sleigh": 3868,

  // Boots
  "Berserker's Greaves": 3006,
  "Sorcerer's Shoes": 3020,
  "Plated Steelcaps": 3047,
  "Mercury's Treads": 3111,
  "Ionian Boots of Lucidity": 3158,
  "Boots of Swiftness": 3009,
  "Symbiotic Soles": 3010,
  "Synchronized Souls": 3013,

  // Starter
  "Doran's Blade": 1055,
  "Doran's Ring": 1056,
  "Doran's Shield": 1054,
  "Long Sword": 1036,
  "Dark Seal": 1082,
  "Tear of the Goddess": 3070,
  "Cull": 1083,

  // Key Components
  "B.F. Sword": 1038,
  "Needlessly Large Rod": 1058,
  "Noonquiver": 6670,
  "Pickaxe": 1037,
  "Recurve Bow": 1043,
  "Serrated Dirk": 3134,
  "Hextech Alternator": 3145,
  "Sheen": 3057,
  "Phage": 3044,
  "Zeal": 3086,
  "Vampiric Scepter": 1053,
  "Hearthbound Axe": 3051,
  "Tiamat": 3077,
  "Oblivion Orb": 3916,
  "Blasting Wand": 1026,
  "Giant's Belt": 1011,
  "Chain Vest": 1031,
  "Negatron Cloak": 1057,
  "Spectre's Cowl": 3211,
  "Bami's Cinder": 6660,
  "Kindlegem": 3067,
  "Catalyst of Aeons": 3803,
  "Kircheis Shard": 2015,

  // Wards/Trinkets
  "Stealth Ward": 3340,
  "Control Ward": 2055,
  "Oracle Lens": 3364,
  "Farsight Alteration": 3363,

  // Support Starters
  "World Atlas": 3865,
  "Runic Compass": 3866,
  "Bounty of Worlds": 3867,
};

/**
 * Get the DDragon image URL for an item by name.
 * Returns null if the item name is not in our mapping.
 */
export function getItemImageUrl(itemName: string, patch = CURRENT_PATCH): string | null {
  const id = ITEM_NAME_TO_ID[itemName];
  if (!id) return null;
  return itemIconUrl(id, patch);
}

// ── Summoner Spell Key Mapping ──

export const SPELL_NAME_TO_KEY: Record<string, string> = {
  "Flash": "SummonerFlash",
  "Ignite": "SummonerDot",
  "Teleport": "SummonerTeleport",
  "Exhaust": "SummonerExhaust",
  "Heal": "SummonerHeal",
  "Ghost": "SummonerHaste",
  "Barrier": "SummonerBarrier",
  "Cleanse": "SummonerBoost",
  "Smite": "SummonerSmite",
  "Mark": "SummonerSnowball",
};

/**
 * Get the DDragon image URL for a summoner spell by its display name.
 */
export function getSpellImageUrl(spellName: string, patch = CURRENT_PATCH): string | null {
  const key = SPELL_NAME_TO_KEY[spellName];
  if (!key) return null;
  return spellIconUrl(key, patch);
}
