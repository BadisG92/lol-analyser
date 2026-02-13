export const EXTRACTION_PROMPT = `Analyse ce screenshot du scoreboard TAB de League of Legends.

INSTRUCTIONS :
- Extrais TOUTES les informations visibles en JSON strict
- Les équipes sont Blue (gauche) et Red (droite)
- Le temps de jeu est en haut au centre
- Les objectifs (drakes, grubs, tours) sont visibles via des icônes
- Pour les items, identifie-les par leur icône. Les items courants :
  * Épées/lames = items AD (Infinity Edge, Bloodthirster, etc.)
  * Baguettes/orbes = items AP (Rabadon, Zhonya, etc.)
  * Boucliers/armures = items tank (Sunfire, Thornmail, etc.)
  * Bottes = boots (Berserker, Sorcerer, etc.)
- Si un élément n'est pas lisible avec certitude, utilise null (PAS de guess)
- Pour les champions, base-toi sur le portrait ET la position dans la liste

RÈGLES DE VALIDATION :
- CS : entre 0 et 600 (>12 CS/min = suspect)
- Levels : entre 1 et 18
- Items : max 7 slots (6 items + 1 ward)
- KDA : pas de valeurs négatives
- game_time_minutes cohérent avec les levels moyens

SCHÉMA JSON :
{
  "game_time_minutes": number,
  "blue_team": {
    "kills": number,
    "towers_destroyed": number,
    "drakes": ["infernal"|"mountain"|"ocean"|"cloud"|"hextech"|"chemtech"|null],
    "grubs": number,
    "herald": boolean,
    "baron": boolean,
    "players": [
      {
        "name": "string (Riot ID visible)",
        "champion": "string (nom exact anglais du champion)",
        "level": number,
        "kills": number,
        "deaths": number,
        "assists": number,
        "cs": number,
        "items": ["item_name"|null],
        "summoner_spells": ["Flash"|"Ignite"|"Teleport"|"Exhaust"|"Heal"|"Ghost"|"Barrier"|"Cleanse"|"Smite"],
        "estimated_role": "top|jungle|mid|adc|support"
      }
    ]
  },
  "red_team": { "...même structure..." },
  "minimap_observations": "string (positions des joueurs visibles, wave states si lisible)",
  "additional_observations": "string (buffs actifs, death timers visibles, anything notable)"
}

EXEMPLE (format attendu pour un joueur) :
{
  "name": "xKairo#EUW",
  "champion": "Jinx",
  "level": 11,
  "kills": 5,
  "deaths": 2,
  "assists": 7,
  "cs": 187,
  "items": ["Kraken Slayer", "Phantom Dancer", "Berserker's Greaves", "Pickaxe", null, null, "Stealth Ward"],
  "summoner_spells": ["Flash", "Heal"],
  "estimated_role": "adc"
}

ORDRE D'EXTRACTION (priorité) :
1. Champions + KDA + CS (critique)
2. Items complétés (power spikes)
3. Levels
4. Objectifs (drakes, tours, grubs, baron)
5. Summoner spells
6. Minimap (best effort)

Réponds UNIQUEMENT avec le JSON valide, aucun texte autour.`;
