/**
 * Static champion reference — Season 15 (Patch 15.x)
 *
 * Run `npx tsx scripts/sync-game-data.ts` to refresh from DDragon.
 * Each champion has: id, name, tags (Fighter/Tank/Mage/Assassin/Marksman/Support),
 * and typical roles (top/jungle/mid/adc/support).
 */

export interface ChampionRef {
  id: string;
  name: string;
  tags: string[];
  roles: string[];
}

export const CHAMPIONS: ChampionRef[] = [
  // A
  { id: "Aatrox", name: "Aatrox", tags: ["Fighter", "Tank"], roles: ["top"] },
  { id: "Ahri", name: "Ahri", tags: ["Mage", "Assassin"], roles: ["mid"] },
  { id: "Akali", name: "Akali", tags: ["Assassin"], roles: ["mid", "top"] },
  { id: "Akshan", name: "Akshan", tags: ["Marksman", "Assassin"], roles: ["mid"] },
  { id: "Alistar", name: "Alistar", tags: ["Tank", "Support"], roles: ["support"] },
  { id: "Ambessa", name: "Ambessa", tags: ["Fighter", "Assassin"], roles: ["top"] },
  { id: "Amumu", name: "Amumu", tags: ["Tank", "Mage"], roles: ["jungle", "support"] },
  { id: "Anivia", name: "Anivia", tags: ["Mage"], roles: ["mid"] },
  { id: "Annie", name: "Annie", tags: ["Mage"], roles: ["mid", "support"] },
  { id: "Aphelios", name: "Aphelios", tags: ["Marksman"], roles: ["adc"] },
  { id: "Ashe", name: "Ashe", tags: ["Marksman", "Support"], roles: ["adc", "support"] },
  { id: "AurelionSol", name: "Aurelion Sol", tags: ["Mage"], roles: ["mid"] },
  { id: "Aurora", name: "Aurora", tags: ["Mage", "Assassin"], roles: ["mid", "top"] },
  { id: "Azir", name: "Azir", tags: ["Mage", "Marksman"], roles: ["mid"] },
  // B
  { id: "Bard", name: "Bard", tags: ["Support", "Mage"], roles: ["support"] },
  { id: "Belveth", name: "Bel'Veth", tags: ["Fighter"], roles: ["jungle"] },
  { id: "Blitzcrank", name: "Blitzcrank", tags: ["Tank", "Fighter"], roles: ["support"] },
  { id: "Brand", name: "Brand", tags: ["Mage"], roles: ["support", "mid"] },
  { id: "Braum", name: "Braum", tags: ["Support", "Tank"], roles: ["support"] },
  { id: "Briar", name: "Briar", tags: ["Fighter", "Assassin"], roles: ["jungle"] },
  // C
  { id: "Caitlyn", name: "Caitlyn", tags: ["Marksman"], roles: ["adc"] },
  { id: "Camille", name: "Camille", tags: ["Fighter", "Tank"], roles: ["top"] },
  { id: "Cassiopeia", name: "Cassiopeia", tags: ["Mage"], roles: ["mid"] },
  { id: "Chogath", name: "Cho'Gath", tags: ["Tank", "Mage"], roles: ["top"] },
  { id: "Corki", name: "Corki", tags: ["Marksman"], roles: ["mid"] },
  // D
  { id: "Darius", name: "Darius", tags: ["Fighter", "Tank"], roles: ["top"] },
  { id: "Diana", name: "Diana", tags: ["Fighter", "Mage"], roles: ["jungle", "mid"] },
  { id: "DrMundo", name: "Dr. Mundo", tags: ["Fighter", "Tank"], roles: ["top", "jungle"] },
  { id: "Draven", name: "Draven", tags: ["Marksman"], roles: ["adc"] },
  // E
  { id: "Ekko", name: "Ekko", tags: ["Assassin", "Fighter"], roles: ["jungle", "mid"] },
  { id: "Elise", name: "Elise", tags: ["Mage", "Fighter"], roles: ["jungle"] },
  { id: "Evelynn", name: "Evelynn", tags: ["Assassin", "Mage"], roles: ["jungle"] },
  { id: "Ezreal", name: "Ezreal", tags: ["Marksman", "Mage"], roles: ["adc"] },
  // F
  { id: "Fiddlesticks", name: "Fiddlesticks", tags: ["Mage"], roles: ["jungle"] },
  { id: "Fiora", name: "Fiora", tags: ["Fighter", "Assassin"], roles: ["top"] },
  { id: "Fizz", name: "Fizz", tags: ["Assassin", "Fighter"], roles: ["mid"] },
  // G
  { id: "Galio", name: "Galio", tags: ["Tank", "Mage"], roles: ["mid", "support"] },
  { id: "Gangplank", name: "Gangplank", tags: ["Fighter"], roles: ["top"] },
  { id: "Garen", name: "Garen", tags: ["Fighter", "Tank"], roles: ["top"] },
  { id: "Gnar", name: "Gnar", tags: ["Fighter", "Tank"], roles: ["top"] },
  { id: "Gragas", name: "Gragas", tags: ["Fighter", "Mage"], roles: ["jungle", "top"] },
  { id: "Graves", name: "Graves", tags: ["Marksman"], roles: ["jungle"] },
  { id: "Gwen", name: "Gwen", tags: ["Fighter"], roles: ["top"] },
  // H
  { id: "Hecarim", name: "Hecarim", tags: ["Fighter", "Tank"], roles: ["jungle"] },
  { id: "Heimerdinger", name: "Heimerdinger", tags: ["Mage"], roles: ["mid", "top", "support"] },
  { id: "Hwei", name: "Hwei", tags: ["Mage"], roles: ["mid", "support"] },
  // I
  { id: "Illaoi", name: "Illaoi", tags: ["Fighter", "Tank"], roles: ["top"] },
  { id: "Irelia", name: "Irelia", tags: ["Fighter", "Assassin"], roles: ["mid", "top"] },
  { id: "Ivern", name: "Ivern", tags: ["Support", "Mage"], roles: ["jungle"] },
  // J
  { id: "Janna", name: "Janna", tags: ["Support", "Mage"], roles: ["support"] },
  { id: "JarvanIV", name: "Jarvan IV", tags: ["Tank", "Fighter"], roles: ["jungle"] },
  { id: "Jax", name: "Jax", tags: ["Fighter", "Assassin"], roles: ["top", "jungle"] },
  { id: "Jayce", name: "Jayce", tags: ["Fighter", "Marksman"], roles: ["top", "mid"] },
  { id: "Jhin", name: "Jhin", tags: ["Marksman", "Mage"], roles: ["adc"] },
  { id: "Jinx", name: "Jinx", tags: ["Marksman"], roles: ["adc"] },
  // K
  { id: "KSante", name: "K'Sante", tags: ["Fighter", "Tank"], roles: ["top"] },
  { id: "Kaisa", name: "Kai'Sa", tags: ["Marksman"], roles: ["adc"] },
  { id: "Kalista", name: "Kalista", tags: ["Marksman"], roles: ["adc"] },
  { id: "Karma", name: "Karma", tags: ["Mage", "Support"], roles: ["support", "mid"] },
  { id: "Karthus", name: "Karthus", tags: ["Mage"], roles: ["jungle", "mid"] },
  { id: "Kassadin", name: "Kassadin", tags: ["Assassin", "Mage"], roles: ["mid"] },
  { id: "Katarina", name: "Katarina", tags: ["Assassin", "Mage"], roles: ["mid"] },
  { id: "Kayle", name: "Kayle", tags: ["Fighter", "Marksman"], roles: ["top"] },
  { id: "Kayn", name: "Kayn", tags: ["Fighter", "Assassin"], roles: ["jungle"] },
  { id: "Kennen", name: "Kennen", tags: ["Mage", "Marksman"], roles: ["top"] },
  { id: "Khazix", name: "Kha'Zix", tags: ["Assassin"], roles: ["jungle"] },
  { id: "Kindred", name: "Kindred", tags: ["Marksman"], roles: ["jungle"] },
  { id: "Kled", name: "Kled", tags: ["Fighter", "Tank"], roles: ["top"] },
  { id: "KogMaw", name: "Kog'Maw", tags: ["Marksman", "Mage"], roles: ["adc"] },
  // L
  { id: "Leblanc", name: "LeBlanc", tags: ["Assassin", "Mage"], roles: ["mid"] },
  { id: "LeeSin", name: "Lee Sin", tags: ["Fighter", "Assassin"], roles: ["jungle"] },
  { id: "Leona", name: "Leona", tags: ["Tank", "Support"], roles: ["support"] },
  { id: "Lillia", name: "Lillia", tags: ["Fighter", "Mage"], roles: ["jungle"] },
  { id: "Lissandra", name: "Lissandra", tags: ["Mage"], roles: ["mid"] },
  { id: "Lucian", name: "Lucian", tags: ["Marksman"], roles: ["adc", "mid"] },
  { id: "Lulu", name: "Lulu", tags: ["Support", "Mage"], roles: ["support"] },
  { id: "Lux", name: "Lux", tags: ["Mage", "Support"], roles: ["support", "mid"] },
  // M
  { id: "Malphite", name: "Malphite", tags: ["Tank", "Fighter"], roles: ["top", "support"] },
  { id: "Malzahar", name: "Malzahar", tags: ["Mage", "Assassin"], roles: ["mid"] },
  { id: "Maokai", name: "Maokai", tags: ["Tank", "Mage"], roles: ["support", "jungle"] },
  { id: "MasterYi", name: "Master Yi", tags: ["Assassin", "Fighter"], roles: ["jungle"] },
  { id: "Mel", name: "Mel", tags: ["Mage"], roles: ["mid"] },
  { id: "Milio", name: "Milio", tags: ["Support"], roles: ["support"] },
  { id: "MissFortune", name: "Miss Fortune", tags: ["Marksman"], roles: ["adc"] },
  { id: "Mordekaiser", name: "Mordekaiser", tags: ["Fighter", "Mage"], roles: ["top"] },
  { id: "Morgana", name: "Morgana", tags: ["Mage", "Support"], roles: ["support", "mid"] },
  // N
  { id: "Naafiri", name: "Naafiri", tags: ["Assassin"], roles: ["mid"] },
  { id: "Nami", name: "Nami", tags: ["Support", "Mage"], roles: ["support"] },
  { id: "Nasus", name: "Nasus", tags: ["Fighter", "Tank"], roles: ["top"] },
  { id: "Nautilus", name: "Nautilus", tags: ["Tank", "Support"], roles: ["support"] },
  { id: "Neeko", name: "Neeko", tags: ["Mage"], roles: ["mid", "support"] },
  { id: "Nidalee", name: "Nidalee", tags: ["Assassin", "Mage"], roles: ["jungle"] },
  { id: "Nilah", name: "Nilah", tags: ["Fighter", "Marksman"], roles: ["adc"] },
  { id: "Nocturne", name: "Nocturne", tags: ["Assassin", "Fighter"], roles: ["jungle"] },
  { id: "Nunu", name: "Nunu & Willump", tags: ["Tank", "Fighter"], roles: ["jungle"] },
  // O
  { id: "Olaf", name: "Olaf", tags: ["Fighter", "Tank"], roles: ["top", "jungle"] },
  { id: "Orianna", name: "Orianna", tags: ["Mage"], roles: ["mid"] },
  { id: "Ornn", name: "Ornn", tags: ["Tank", "Fighter"], roles: ["top"] },
  // P
  { id: "Pantheon", name: "Pantheon", tags: ["Fighter", "Assassin"], roles: ["top", "mid", "support"] },
  { id: "Poppy", name: "Poppy", tags: ["Tank", "Fighter"], roles: ["jungle", "top", "support"] },
  { id: "Pyke", name: "Pyke", tags: ["Assassin", "Support"], roles: ["support"] },
  // Q
  { id: "Qiyana", name: "Qiyana", tags: ["Assassin", "Fighter"], roles: ["mid"] },
  { id: "Quinn", name: "Quinn", tags: ["Marksman", "Assassin"], roles: ["top"] },
  // R
  { id: "Rakan", name: "Rakan", tags: ["Support"], roles: ["support"] },
  { id: "Rammus", name: "Rammus", tags: ["Tank", "Fighter"], roles: ["jungle"] },
  { id: "RekSai", name: "Rek'Sai", tags: ["Fighter"], roles: ["jungle"] },
  { id: "Rell", name: "Rell", tags: ["Tank", "Support"], roles: ["support"] },
  { id: "RenataGlasc", name: "Renata Glasc", tags: ["Support", "Mage"], roles: ["support"] },
  { id: "Renekton", name: "Renekton", tags: ["Fighter", "Tank"], roles: ["top"] },
  { id: "Rengar", name: "Rengar", tags: ["Assassin", "Fighter"], roles: ["jungle", "top"] },
  { id: "Riven", name: "Riven", tags: ["Fighter", "Assassin"], roles: ["top"] },
  { id: "Rumble", name: "Rumble", tags: ["Fighter", "Mage"], roles: ["top", "mid"] },
  { id: "Ryze", name: "Ryze", tags: ["Mage", "Fighter"], roles: ["mid", "top"] },
  // S
  { id: "Samira", name: "Samira", tags: ["Marksman"], roles: ["adc"] },
  { id: "Sejuani", name: "Sejuani", tags: ["Tank", "Fighter"], roles: ["jungle"] },
  { id: "Senna", name: "Senna", tags: ["Marksman", "Support"], roles: ["support", "adc"] },
  { id: "Seraphine", name: "Seraphine", tags: ["Mage", "Support"], roles: ["support", "adc"] },
  { id: "Sett", name: "Sett", tags: ["Fighter", "Tank"], roles: ["top", "support"] },
  { id: "Shaco", name: "Shaco", tags: ["Assassin"], roles: ["jungle", "support"] },
  { id: "Shen", name: "Shen", tags: ["Tank"], roles: ["top", "support"] },
  { id: "Shyvana", name: "Shyvana", tags: ["Fighter", "Tank"], roles: ["jungle"] },
  { id: "Singed", name: "Singed", tags: ["Tank", "Fighter"], roles: ["top"] },
  { id: "Sion", name: "Sion", tags: ["Tank", "Fighter"], roles: ["top"] },
  { id: "Sivir", name: "Sivir", tags: ["Marksman"], roles: ["adc"] },
  { id: "Skarner", name: "Skarner", tags: ["Fighter", "Tank"], roles: ["jungle"] },
  { id: "Smolder", name: "Smolder", tags: ["Marksman", "Mage"], roles: ["adc", "mid"] },
  { id: "Sona", name: "Sona", tags: ["Support", "Mage"], roles: ["support"] },
  { id: "Soraka", name: "Soraka", tags: ["Support", "Mage"], roles: ["support"] },
  { id: "Swain", name: "Swain", tags: ["Mage", "Fighter"], roles: ["support", "mid"] },
  { id: "Sylas", name: "Sylas", tags: ["Mage", "Assassin"], roles: ["mid"] },
  { id: "Syndra", name: "Syndra", tags: ["Mage"], roles: ["mid"] },
  // T
  { id: "TahmKench", name: "Tahm Kench", tags: ["Support", "Tank"], roles: ["top", "support"] },
  { id: "Taliyah", name: "Taliyah", tags: ["Mage"], roles: ["jungle", "mid"] },
  { id: "Talon", name: "Talon", tags: ["Assassin"], roles: ["mid", "jungle"] },
  { id: "Taric", name: "Taric", tags: ["Support", "Fighter"], roles: ["support"] },
  { id: "Teemo", name: "Teemo", tags: ["Marksman", "Mage"], roles: ["top"] },
  { id: "Thresh", name: "Thresh", tags: ["Support", "Fighter"], roles: ["support"] },
  { id: "Tristana", name: "Tristana", tags: ["Marksman", "Assassin"], roles: ["adc", "mid"] },
  { id: "Trundle", name: "Trundle", tags: ["Fighter", "Tank"], roles: ["jungle", "top"] },
  { id: "Tryndamere", name: "Tryndamere", tags: ["Fighter", "Assassin"], roles: ["top"] },
  { id: "TwistedFate", name: "Twisted Fate", tags: ["Mage"], roles: ["mid"] },
  { id: "Twitch", name: "Twitch", tags: ["Marksman", "Assassin"], roles: ["adc"] },
  // U
  { id: "Udyr", name: "Udyr", tags: ["Fighter", "Tank"], roles: ["jungle"] },
  { id: "Urgot", name: "Urgot", tags: ["Fighter", "Tank"], roles: ["top"] },
  // V
  { id: "Varus", name: "Varus", tags: ["Marksman", "Mage"], roles: ["adc"] },
  { id: "Vayne", name: "Vayne", tags: ["Marksman", "Assassin"], roles: ["adc", "top"] },
  { id: "Veigar", name: "Veigar", tags: ["Mage"], roles: ["mid", "support"] },
  { id: "Velkoz", name: "Vel'Koz", tags: ["Mage"], roles: ["support", "mid"] },
  { id: "Vex", name: "Vex", tags: ["Mage"], roles: ["mid"] },
  { id: "Vi", name: "Vi", tags: ["Fighter", "Assassin"], roles: ["jungle"] },
  { id: "Viego", name: "Viego", tags: ["Assassin", "Fighter"], roles: ["jungle"] },
  { id: "Viktor", name: "Viktor", tags: ["Mage"], roles: ["mid"] },
  { id: "Vladimir", name: "Vladimir", tags: ["Mage"], roles: ["mid", "top"] },
  { id: "Volibear", name: "Volibear", tags: ["Fighter", "Tank"], roles: ["top", "jungle"] },
  // W
  { id: "Warwick", name: "Warwick", tags: ["Fighter", "Tank"], roles: ["jungle", "top"] },
  { id: "MonkeyKing", name: "Wukong", tags: ["Fighter", "Tank"], roles: ["jungle", "top"] },
  // X
  { id: "Xayah", name: "Xayah", tags: ["Marksman"], roles: ["adc"] },
  { id: "Xerath", name: "Xerath", tags: ["Mage"], roles: ["support", "mid"] },
  { id: "XinZhao", name: "Xin Zhao", tags: ["Fighter", "Assassin"], roles: ["jungle"] },
  // Y
  { id: "Yasuo", name: "Yasuo", tags: ["Fighter", "Assassin"], roles: ["mid", "adc"] },
  { id: "Yone", name: "Yone", tags: ["Fighter", "Assassin"], roles: ["mid", "top"] },
  { id: "Yorick", name: "Yorick", tags: ["Fighter", "Tank"], roles: ["top"] },
  { id: "Yuumi", name: "Yuumi", tags: ["Support", "Mage"], roles: ["support"] },
  // Z
  { id: "Zac", name: "Zac", tags: ["Tank", "Fighter"], roles: ["jungle"] },
  { id: "Zed", name: "Zed", tags: ["Assassin"], roles: ["mid"] },
  { id: "Zeri", name: "Zeri", tags: ["Marksman"], roles: ["adc"] },
  { id: "Ziggs", name: "Ziggs", tags: ["Mage"], roles: ["mid", "adc"] },
  { id: "Zilean", name: "Zilean", tags: ["Support", "Mage"], roles: ["support", "mid"] },
  { id: "Zoe", name: "Zoe", tags: ["Mage"], roles: ["mid"] },
  { id: "Zyra", name: "Zyra", tags: ["Mage", "Support"], roles: ["support"] },
];

/** All champion names as a flat list (for prompt injection). */
export const CHAMPION_NAMES: string[] = CHAMPIONS.map((c) => c.name);

/** Lookup champion by name (case-insensitive). */
export function findChampion(name: string): ChampionRef | undefined {
  const lower = name.toLowerCase();
  return CHAMPIONS.find(
    (c) => c.name.toLowerCase() === lower || c.id.toLowerCase() === lower
  );
}
