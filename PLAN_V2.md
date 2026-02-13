# LoL AI Coach - Plan V2 (Post-Expert Review)

> Ce plan intègre les retours de 5 experts : Senior iOS Dev, Staff Backend Engineer,
> Pro Coach LEC/LCK, AI/ML Prompt Engineer, Product Strategist ex-Riot Games.
> + Les clarifications du fondateur sur le flow réel de l'app.

---

## 1. Vision produit (corrigée)

Application iOS qui agit comme un **coach IA conversationnel** par game.

**Flow réel (corrigé par le fondateur) :**

```
AVANT LA GAME (loading screen / champ select)
│
├─ L'utilisateur donne son Riot ID (une seule fois, sauvegardé)
├─ L'app détecte la game (via screenshot ou input manuel)
├─ FETCH UNIQUE : OP.GG MCP pour les 10 joueurs (pas de Riot API)
├─ L'IA donne un PLAN DE JEU INITIAL :
│   ├─ Build complet recommandé (item path)
│   ├─ Ordre de sorts (skill order)
│   ├─ Matchup analysis (lane opponent)
│   ├─ Plan macro par phase (early/mid/late)
│   └─ Win conditions de chaque équipe
│
PENDANT LA GAME (TAB screen quand le joueur meurt ou a du temps)
│
├─ L'utilisateur prend une photo du TAB screen
├─ Le TAB montre : KDA, CS, items, levels, minimap, objectifs
├─ L'IA analyse la photo ET garde le contexte des analyses précédentes
├─ Chat conversationnel : chaque game = un thread
│   ├─ Pas besoin de re-fetch les données API
│   ├─ L'IA suit l'évolution de la game (screenshots successifs)
│   └─ Conseils de plus en plus précis au fil de la game
│
APRÈS LA GAME
│
└─ Résumé et review sauvegardé dans l'historique
```

**Différenciateur clé** : Ce n'est PAS un outil de stats. C'est un **coach conversationnel qui suit ta game en temps réel** via des snapshots. Aucun concurrent iOS ne fait ça.

---

## 2. Critique Expert #1 : Senior iOS Developer

### Architecture

**MVVM avec @Observable (iOS 17+) est le bon choix pour un MVP.** TCA serait over-engineered pour une app avec 3-4 écrans. Mais il faut structurer pour le chat conversationnel :

```swift
// Le coeur de l'architecture : une GameSession qui persiste pendant toute la game
@Observable
class GameSession {
    let id: UUID
    let startedAt: Date
    var riotId: String
    var region: Region
    var players: [Player]           // Fetché une fois au début
    var analyses: [Analysis]        // Chaque screenshot = une analyse
    var messages: [CoachMessage]    // Le thread de coaching
    var gamePhase: GamePhase        // .early, .mid, .late (déduit du temps)

    // Le contexte complet pour l'IA, construit incrémentalement
    var aiContext: AIContext {
        AIContext(players: players, analyses: analyses, messages: messages)
    }
}
```

### UX critique : la latence

Le joueur est MORT quand il TAB → il a **10-60 secondes** de death timer. C'est suffisant si :
- L'upload est rapide (image compressée 200-400KB)
- Le streaming SSE affiche les premiers mots en 3-5s
- Le conseil prioritaire ("focus X, build Y") arrive en premier

**Pattern recommandé** : Skeleton loading → Streaming text qui apparaît mot par mot → Sections qui se remplissent progressivement.

### Camera / Image

```
PhotosPicker (iOS 16+) pour import galerie = SUFFISANT pour le MVP.
Pas besoin d'AVFoundation ni de camera custom au début.
Le joueur fera : screenshot iOS → partage vers l'app OU galerie → import.
```

**Pièges à éviter** :
- Rotation EXIF : toujours normaliser l'orientation avant envoi
- Compression : JPEG quality 0.6 + resize à 1920px max côté long
- Format : TOUJOURS envoyer en `multipart/form-data`, PAS en base64

### App Store Review

**Risques identifiés** :
- Apple rejette les apps "shell" qui sont juste un wrapper autour d'une API IA → L'app doit avoir de la valeur native (historique, UI riche, stats locales)
- Guideline 4.2 (Minimum Functionality) : il faut plus qu'un champ texte + réponse IA
- Guideline 3.1.1 (In-App Purchase) : si freemium, les achats DOIVENT passer par IAP (Apple prend 30%)
- PAS de risque copyright si on utilise les noms de champions/items (c'est du fair use / données publiques)

---

## 3. Critique Expert #2 : Staff Backend Engineer

### Architecture serveur révisée

```
                         ┌────────────────────────────┐
                         │      iOS App (SwiftUI)      │
                         │  - PhotosPicker             │
                         │  - Chat UI (streaming)      │
                         │  - SwiftData (local)        │
                         └─────────┬──────────────────┘
                                   │ HTTPS + SSE
                                   ▼
┌──────────────────────────────────────────────────────────────┐
│                   API Gateway (Hono on Cloudflare Workers)    │
│  - Auth (JWT + Apple Sign In)                                │
│  - Rate limiting par user (5 analyses gratuites/jour)         │
│  - Request validation                                        │
│  - Image upload → R2 (Cloudflare storage)                    │
└───────────┬──────────────────────────────┬──────────────────┘
            │                              │
            ▼                              ▼
   ┌────────────┐              ┌──────────────────────┐
   │ Claude API │              │  OP.GG MCP           │
   │ (Vision +  │              │  (Players, meta,     │
   │  Coaching) │              │   builds, counters,  │
   │            │              │   match history)     │
   └────────────┘              └──────────────────────┘
                                         │
                                  ┌──────┴──────┐
                                  │ DDragon /   │
                                  │ CDragon     │
                                  │ (Static)    │
                                  └─────────────┘
```

**NOTE V3 : Riot API complètement retirée.** OP.GG MCP couvre tous les besoins :
- Données joueurs (rank, LP, win rate) via `lol-summoner-search`
- Match history via `lol-summoner-game-history`
- Builds/runes/counters via `lol-champion-analysis`
- Meta/tier list via `lol-champion-meta-data`
- Autofill detection via `lol-champion-positions-data`

Avantages : pas de clé API, pas de rate limiting strict, données déjà agrégées.

### Pourquoi Hono + Cloudflare Workers (pas Express/Node)

| Critère | Express (Node.js) | Hono (CF Workers) |
|---------|-------------------|-------------------|
| Cold start | ~200-500ms | ~0ms (edge) |
| Coût mensuel (MVP) | $5-15/mo (Railway) | $0 (free tier: 100K req/jour) |
| Scaling | Manuel | Auto |
| R2 storage | S3 séparé ($$$) | Inclus (10GB free) |
| DDoS protection | À configurer | Incluse |
| SSE support | Natif | Natif |
| Global latency | Un seul datacenter | 300+ edge locations |

### Orchestration des appels API (flow optimisé — sans Riot API)

```
GAME INIT (une seule fois) :
┌─────────────────────────────────────────────────────────┐
│ 1. Claude Vision analyse le 1er screenshot              │
│    └─> Extrait les 10 noms de joueurs + champions       │
│                                                         │
│ 2. EN PARALLÈLE (Promise.all) :                         │
│    ├─> 10x OP.GG MCP: lol-summoner-search (rank, stats) │
│    ├─> 10x OP.GG MCP: lol-summoner-game-history         │
│    ├─> 10x OP.GG MCP: lol-champion-analysis (builds)    │
│    ├─> OP.GG MCP: lol-champion-positions-data (autofill)│
│    └─> DDragon: patch version + item data (caché 24h)   │
│                                                         │
│ 3. Claude coaching: plan de jeu initial (SSE stream)    │
│    └─> Contexte = tout ce qui précède                   │
└─────────────────────────────────────────────────────────┘
Total: 1 Claude Vision + ~30 OP.GG MCP + 1 DDragon + 1 Claude coaching
PAS DE RIOT API. Zéro clé à gérer.

SCREENSHOTS SUIVANTS (pendant la game) :
┌─────────────────────────────────────────────────────────┐
│ 1. Claude Vision analyse le nouveau screenshot          │
│    └─> Extrait: KDA, CS, items, levels, objectifs,      │
│        minimap state, temps de jeu                       │
│                                                         │
│ 2. Claude coaching (SSE stream)                         │
│    └─> Contexte = données initiales + TOUTES les        │
│        analyses précédentes (conversation thread)       │
│    └─> PAS de nouveaux appels OP.GG                    │
└─────────────────────────────────────────────────────────┘
Total: 1 Claude Vision + 1 Claude coaching (ULTRA RAPIDE ~3-8s)
```

### Stratégie de cache

| Donnée | TTL Cache | Pourquoi |
|--------|-----------|----------|
| DDragon (items, champions) | 24h | Change seulement au patch |
| OP.GG meta/builds | 6h | Évolue lentement |
| OP.GG summoner data | 30min | Peut changer après chaque game |
| OP.GG champion analysis | 12h | Builds stables sur un patch |

### Sécurité MVP

1. **Auth** : Apple Sign In (obligatoire iOS) → JWT signé → vérifié côté Workers
2. **Rate limit** : 5 analyses gratuites/jour par compte, KV store pour le compteur
3. **Image validation** : Check magic bytes (JPEG/PNG), taille max 5MB, resize server-side
4. **API keys** : Cloudflare Workers Secrets (équivalent env vars chiffrés)
5. **Abuse protection** : Si un user dépasse 20 analyses/jour même payant → flag + review

---

## 4. Critique Expert #3 : Pro Coach LEC/LCK

### Ce qu'un coach regarde EN PREMIER sur le TAB screen

```
PRIORITÉ 1 (les 2 premières secondes) :
1. Score global (kills par équipe) → qui a le momentum
2. Gold des joueurs (déduit des items) → qui est ahead/behind
3. CS par minute → efficacité farming (bon indicateur de level)
4. Items complétés vs composants → qui a atteint un power spike

PRIORITÉ 2 (analyse rapide) :
5. Niveaux relatifs → XP advantage = lane dominance
6. Qui est mort récemment → fenêtre d'opportunité
7. Summoner spells (si visible) → Flash/TP cooldowns
8. Objectifs (drakes, tours, grubs) visible en bas du TAB

PRIORITÉ 3 (analyse profonde, via historique) :
9. Tendances des joueurs (agressif, passif, one-trick)
10. Autofill detection → weak link exploitable
```

### Le TAB screen montre PLUS qu'on pense

Le TAB de League of Legends en 2025 affiche :
- **KDA** de chaque joueur ✓
- **CS (Creep Score)** ✓
- **Champion + Level** ✓
- **Items** (6 slots + ward) ✓
- **Summoner spells** ✓
- **Temps de game** ✓
- **Score des équipes** (kills) ✓
- **Tours détruites** (icônes en haut) ✓
- **Drakes pris** (icônes sous le score) ✓
- **Grubs / Rift Herald** (icônes) ✓
- **Baron buff** (visible sur les champions) ✓
- **Minimap** (en bas à gauche, TOUJOURS visible même en TAB) ✓

**Ce que le TAB ne montre PAS** :
- Gold exact de chaque joueur (estimable via items)
- Cooldowns des sorts
- Runes
- État des vagues de minions (wave state)
- Vision / wards placées

### Framework de coaching par phase de jeu

```
PHASE 1 : PRE-GAME / LOADING SCREEN (0:00)
├── Matchup analysis : qui gagne chaque lane en théorie
├── Jungle path prediction : où le jungler adverse va probablement start
├── Level 1-3 plan : trade patterns, all-in potential
├── First back target : quel item viser au premier recall
├── Ward timing : quand/où poser le premier ward
└── Win condition macro : quel est le plan pour gagner la game

PHASE 2 : EARLY GAME (0:00 - 14:00)
├── CS benchmark : es-tu au-dessus/en-dessous de ton CS/min attendu ?
├── Trade assessment : peux-tu trade ton lane opponent maintenant ?
├── Jungle tracking : "leur jungler était bot il y a 30s, il est probablement mid/top"
├── First drake decision : contester ou pas ? basé sur prio des lanes
├── Grubs assessment : si top/jgl, les grubs valent-ils le détour ?
├── Roam timing : quand pousser et roam vs stay in lane
└── Item spike alert : "tu as 1 composant d'avance, force un trade"

PHASE 3 : MID GAME (14:00 - 25:00)
├── Grouping vs splitting : basé sur la compo et qui est ahead
├── Objectif prioritaire : drake > baron > tour ? Ça dépend du context
├── Vision control : où placer les wards pour le prochain objectif
├── Teamfight plan : qui engage, qui focus, qui peel
├── Catch potential : "leur ADC est souvent seul side lane, punissez"
├── Power spike tracking : "Kaisa a 2 items, elle va faire mal maintenant"
└── Gold efficiency : "vous avez 2K gold d'avance, forcez un objectif"

PHASE 4 : LATE GAME (25:00+)
├── One-fight-wins : "le prochain teamfight peut décider la game"
├── Baron/Elder dance : positionnement et timing
├── Split push pressure : "envoyer X splitpush, groupez les 4 autres"
├── Death timer punishment : "leur mid est mort 40s, rush baron"
├── Build finalization : derniers items défensifs/offensifs
└── Comp expiration : "votre compo est meilleure maintenant, forcez"
```

### Skill order et build : données nécessaires

Pour donner un **build et skill order fiable**, il faut :
1. **OP.GG MCP `lol-champion-analysis`** : donne le build optimal + skill order + runes par matchup
2. **OP.GG MCP `lol-champion-meta-data`** : donne le build le plus populaire et le plus performant
3. **Context de la game** : adapter le build en cours de game (anti-heal, armor pen, MR, etc.)

**Exemple de conseil build adaptatif :**
```
"Tu es Jinx vs une compo avec beaucoup de tanks (Ornn, Sejuani).
Build recommandé : Kraken > PD > LDR (le Lord Dom est crucial ici,
avant le IE contrairement au build standard).
Ils ont aussi Soraka → achète un Executioner's après ton 2ème item."
```

---

## 5. Critique Expert #4 : AI/ML Prompt Engineer

### Claude Vision : fiabilité réelle sur le TAB screen

| Élément | Difficulté | Fiabilité estimée | Notes |
|---------|-----------|-------------------|-------|
| Noms des joueurs | Moyenne | 85-95% | Caractères spéciaux, langues, polices custom |
| Champions (portraits) | Facile | 95-99% | Visuels distinctifs, même avec skins |
| Niveaux | Facile | 95-99% | Gros chiffres clairs |
| KDA | Facile | 95-99% | Format standard X/Y/Z |
| CS | Facile | 95-99% | Chiffre isolé |
| Items (icônes) | Difficile | 70-85% | Petites icônes, 200+ items possibles |
| Temps de game | Facile | 99% | Affiché en haut |
| Objectifs (drakes) | Moyen | 80-90% | Petites icônes, couleurs |
| Minimap | Très difficile | 40-60% | Trop petit, trop de détails |
| Score équipes | Facile | 99% | Gros chiffres |
| Tours détruites | Moyen | 75-85% | Icônes grisées/colorées |

### Stratégie de modèles (coûts optimisés)

```
EXTRACTION (TAB screen → JSON structuré) :
└─ Claude Haiku 4.5 — rapide (~1-2s), pas cher (~$0.005/image)
   Suffisant pour de l'OCR structuré

COACHING (analyse + plan de jeu) :
└─ Claude Sonnet 4.5 — bon équilibre qualité/coût (~$0.01-0.03)
   Assez intelligent pour du coaching stratégique

PAS besoin d'Opus sauf pour des edge cases très complexes.
```

### Prompt d'extraction V2 (optimisé)

```
Analyse ce screenshot du scoreboard TAB de League of Legends.

INSTRUCTIONS :
- Extrais TOUTES les informations visibles en JSON
- Les équipes sont Blue (gauche) et Red (droite)
- Le temps de jeu est en haut au centre
- Les objectifs (drakes, grubs, tours) sont visibles via des icônes
- Si un élément n'est pas lisible, utilise "unknown"
- Pour les items, décris l'icône si tu ne reconnais pas le nom exact

SCHÉMA JSON ATTENDU :
{
  "game_time_minutes": number,
  "blue_team": {
    "kills": number,
    "towers_destroyed": number,
    "drakes": ["type1", "type2"],
    "grubs": number,
    "herald": boolean,
    "baron": boolean,
    "players": [
      {
        "name": "string (Riot ID)",
        "champion": "string (nom exact du champion)",
        "level": number,
        "kills": number,
        "deaths": number,
        "assists": number,
        "cs": number,
        "items": ["item1", "item2", ...],
        "summoner_spells": ["spell1", "spell2"],
        "estimated_role": "top|jungle|mid|adc|support"
      }
    ]
  },
  "red_team": { ... même structure ... },
  "minimap_observations": "string (description libre de ce que tu vois sur la minimap)",
  "additional_observations": "string (tout ce qui semble notable)"
}

CHAMPION RECOGNITION AIDE :
Si tu hésites sur un champion, base-toi sur :
- Le portrait (splash art circle)
- Le rôle déduit de la position dans la liste
- Les items qui correspondent à un type de champion

Réponds UNIQUEMENT avec le JSON, pas de texte autour.
```

### Prompt de coaching V2 (adaptatif par phase)

```
Tu es un analyste stratégique de League of Legends de niveau professionnel.
Tu coaches un joueur EN TEMPS RÉEL pendant sa game.

═══════════════════════════════════════════
DONNÉES DU JOUEUR COACHÉ
═══════════════════════════════════════════
- Riot ID : {riot_id}
- Champion : {champion}
- Rôle : {role}
- Rank : {rank}
- Stats actuelles : {kills}/{deaths}/{assists}, {cs} CS, Level {level}
- Items actuels : {items}
- Opponent direct : {lane_opponent_champion} ({lane_opponent_stats})

═══════════════════════════════════════════
ÉTAT DE LA GAME (extrait du TAB screen)
═══════════════════════════════════════════
Temps : {game_time} minutes
Score : Blue {blue_kills} - {red_kills} Red
Objectifs : {objectives_summary}
Tours : {towers_summary}

BLUE TEAM :
{formatted_blue_team_data}

RED TEAM :
{formatted_red_team_data}

═══════════════════════════════════════════
DONNÉES PRÉ-GAME (fetchées au début, ne changent pas)
═══════════════════════════════════════════
{player_histories_and_ranks}

═══════════════════════════════════════════
HISTORIQUE DE COACHING CETTE GAME
═══════════════════════════════════════════
{previous_analyses_and_advice}

═══════════════════════════════════════════
INSTRUCTIONS DE COACHING
═══════════════════════════════════════════

Adapte TOUT ton coaching à la phase de jeu actuelle :

SI game_time < 14 min (EARLY GAME) :
- Focus sur le laning : trades, CS, timing de back
- Jungle tracking : prédis la position du jungler adverse
- Premier objectif : drake ou grubs ?
- Itemisation : quoi acheter au prochain back

SI 14 min ≤ game_time < 25 min (MID GAME) :
- Macro : split ou group ?
- Objectif prioritaire à contester
- Qui est le carry dans chaque équipe (basé sur items + KDA)
- Teamfight positioning

SI game_time ≥ 25 min (LATE GAME) :
- Win condition finale : comment finir la game
- Baron/Elder dance
- Erreur fatale à ne pas commettre
- Build final

DANS TOUS LES CAS, fournis :

1. ⚡ PRIORITÉ IMMÉDIATE (1 phrase, ce que le joueur doit faire LÀ maintenant)
2. 📊 ÉTAT DE LA GAME (qui gagne, pourquoi, gold diff estimée)
3. 🎯 PLAN D'ACTION (les 3-5 prochaines minutes, concret et actionnable)
4. 🛒 ITEM SUIVANT (quel item acheter et pourquoi DANS CE CONTEXTE)
5. ⚔️ TEAMFIGHT (qui focus, qui éviter, comment se positionner)
6. ⚠️ DANGER (le piège à éviter, l'erreur qui ferait perdre)

FORMAT : Sois BREF et DIRECT. Le joueur est mort et a 20-60 secondes
pour lire. Pas de paragraphes. Des bullet points. Du concret.

LANGUE : Français.
NIVEAU DU JOUEUR : Adapte le vocabulaire à un joueur {rank}.
```

### Optimisation des coûts avec prompt caching

```
SYSTEM PROMPT (caché, réutilisé pour toute la game) :
├── Persona du coach (instructions générales)
├── Liste complète des champions (170+)
├── Items du patch actuel + stats
├── Meta data (tier list, win rates)
├── Framework de coaching par phase
└── JSON Schema d'extraction
→ Ce system prompt est envoyé UNE FOIS et caché par Claude
→ Économie de ~80% sur les tokens d'input pour les messages suivants

USER PROMPT (change à chaque screenshot) :
├── L'image du TAB screen
├── Les données de la game actuelle
└── L'historique de coaching
```

**Coût estimé réel (avec caching)** :

| Étape | Modèle | Input tokens | Output tokens | Coût |
|-------|--------|-------------|---------------|------|
| Game init (extraction) | Haiku | ~1500 (image) + ~500 (prompt) | ~800 | ~$0.002 |
| Game init (enrichissement + coaching) | Sonnet | ~5000 (contexte) | ~1500 | ~$0.03 |
| Screenshot suivant (extraction) | Haiku | ~1500 + ~300 (cached) | ~800 | ~$0.001 |
| Screenshot suivant (coaching) | Sonnet | ~3000 (cached) + ~2000 (delta) | ~1000 | ~$0.015 |
| **Total game init** | | | | **~$0.03** |
| **Chaque screenshot suivant** | | | | **~$0.016** |
| **Game complète (init + 5 screenshots)** | | | | **~$0.11** |

### Edge cases et robustesse

**Photo floue / angle** : Claude Vision gère raisonnablement bien les angles jusqu'à ~30°. Au-delà, ajouter une instruction : "Si l'image est prise en angle, corrige mentalement la perspective pour lire le texte."

**Résolution variable** : Demander côté client de resize à 1920x1080 MAX. En dessous de 720p, prévenir l'utilisateur que la qualité est insuffisante.

**Langues du client LoL** : Les noms de champions sont les mêmes dans toutes les langues (Aatrox = Aatrox). Les items peuvent varier. Inclure dans le system prompt : "Les items peuvent être affichés dans n'importe quelle langue. Identifie-les par leur icône plutôt que par leur texte."

---

## 6. Critique Expert #5 : Product Strategist

### Marché et différenciation

Le marché du coaching LoL est estimé à **$500M+/an** (incluant boosting, coaching humain, apps).
~180M de joueurs actifs mensuels LoL. ~65% jouent sur mobile-first markets (Asie) mais les joueurs PC sont les plus engagés.

**Vrai différenciateur** (pas juste "c'est sur iOS") :
1. **Coach conversationnel** : Aucun concurrent ne fait du coaching adaptatif game par game
2. **Zero setup** : Pas d'overlay, pas de desktop app, pas d'Overwolf. Juste ton téléphone
3. **Contextuel** : Le coach apprend ta game en temps réel (vs Blitz qui donne les mêmes stats à tout le monde)

### User persona

```
Nom : "Lucas", 19 ans
Rank : Gold 2 (le gros du marché : Silver-Gold-Platinum = 60% des joueurs ranked)
Setup : PC gaming + iPhone à côté
Frustration : "Je sais pas quoi faire en mid game, je gagne ma lane mais je perds la game"
Motivation : Monter Plat/Diamant
Budget : Prêt à payer 5-10€/mois si ça l'aide vraiment
```

### Monétisation recommandée

```
FREE TIER :
├── 3 analyses par jour
├── Plan de jeu initial (pré-game)
├── 1 screenshot coaching par game
└── Historique 7 jours

PREMIUM (€7.99/mois ou €49.99/an) :
├── Analyses illimitées
├── Screenshots illimités par game
├── Coaching complet par phase
├── Historique illimité
├── Analyse post-game détaillée
└── Progression tracking
```

**Unit economics** :
- Coût par game : ~$0.11 (init + 5 screenshots)
- Free user (1 game/jour, 2 screenshots) : ~$0.05/jour = ~$1.50/mois
- Premium user (3 games/jour, 5 screenshots) : ~$0.33/jour = ~$10/mois
- Premium revenue : €7.99/mois - 30% Apple = €5.59
- **Marge par premium user** : €5.59 - $10 = **NÉGATIF au début**
- → Il faut optimiser les coûts IA (caching agressif, Haiku partout possible)
- → Ou augmenter le prix à €9.99/mois

### Go-to-market

```
Phase 1 : Beta fermée (100 joueurs)
├── Recrutement via r/leagueoflegends, r/summonerschool
├── Discord privé pour feedback
└── Itérer sur la qualité du coaching

Phase 2 : Lancement soft (1000 joueurs)
├── TikTok / YouTube Shorts : "J'ai utilisé un coach IA en ranked"
├── Contenu créé par les beta testeurs
└── Offre de lancement : 1 mois gratuit premium

Phase 3 : Scale (10K+ joueurs)
├── Partenariats créateurs LoL (Caedrel, Agurin, etc.)
├── App Store Optimization (ASO)
└── Referral program : invite un ami = 1 semaine premium gratuite
```

### Risques business avec mitigations

| Risque | Probabilité | Impact | Mitigation |
|--------|------------|--------|------------|
| Riot interdit l'app | Faible | Fatal | L'app ne touche pas le client, positionnement éducatif, demander un avis à Riot DevRel AVANT le lancement |
| Apple rejette | Moyenne | Bloquant | UI native riche, pas juste un wrapper IA, soumettre une demo video avec la review |
| Coûts API explosent | Moyenne | Financier | Kill switch, quotas stricts, monitoring en temps réel des coûts, migration vers des modèles moins chers si besoin |
| Claude change ses prix | Faible | Financier | Architecture modulaire, possibilité de switcher vers OpenAI/Gemini |
| Un concurrent copie | Élevée | Compétitif | First mover advantage, qualité du coaching, communauté |

---

## 7. Sources de données (recherche complète)

### Data Dragon (Riot officiel, statique, gratuit)

```
Patch actuel : GET https://ddragon.leagueoflegends.com/api/versions.json → [0]
Champions    : GET https://ddragon.leagueoflegends.com/cdn/{v}/data/fr_FR/champion.json
Items        : GET https://ddragon.leagueoflegends.com/cdn/{v}/data/fr_FR/item.json
Runes        : GET https://ddragon.leagueoflegends.com/cdn/{v}/data/fr_FR/runesReforged.json
Spells       : GET https://ddragon.leagueoflegends.com/cdn/{v}/data/fr_FR/summoner.json
```
- Auth : AUCUNE
- Rate limit : AUCUN (CDN statique)
- MAJ : à chaque patch (toutes les 2 semaines)

### Community Dragon (plus complet, plus précis)

```
Items (complets) : GET https://raw.communitydragon.org/latest/plugins/rcp-be-lol-game-data/global/default/v1/items.json
Champions        : GET https://raw.communitydragon.org/latest/plugins/rcp-be-lol-game-data/global/default/v1/champion-summary.json
```
- Auth : AUCUNE
- Rate limit : AUCUN
- Avantage : Stats d'items plus précises que DDragon

### OP.GG MCP Server (DÉCOUVERTE MAJEURE)

```
URL    : https://mcp-api.op.gg/mcp (StreamableHTTP)
GitHub : github.com/opgginc/opgg-mcp
Auth   : AUCUNE (gratuit)
```

**Outils disponibles pour LoL :**

| Tool MCP | Ce qu'il donne | Usage dans l'app |
|----------|---------------|-----------------|
| `lol-summoner-search` | Stats, rank, historique d'un joueur | Init game : profiler les 10 joueurs |
| `lol-summoner-game-history` | Matchs récents détaillés | Init game : tendances récentes |
| `lol-champion-analysis` | Win rate, builds, counters, skill order | Init game : plan de build + matchup |
| `lol-champion-meta-data` | Meta stats du patch actuel | System prompt IA : données meta |
| `lol-champion-positions-data` | Win rate par rôle | Détection autofill |
| `lol-champion-leader-board` | Top players par champion | Contexte optionnel |

**V3 UPDATE** : L'OP.GG MCP couvre TOUT ce dont on a besoin. Riot API retirée du MVP.
On pourra l'ajouter plus tard si besoin de données granulaires (timelines, gold/xp par minute).

### Stratégie data (simplifiée)

```
SEULES SOURCES NÉCESSAIRES :
├── OP.GG MCP : données joueurs + meta + builds + counters → GRATUIT
├── DDragon/CDragon : données statiques (items, champions, patch) → GRATUIT
└── Claude API : analyse d'image + coaching → PAYANT (seul coût)

OPTIONNEL (futur) :
└── Riot API : si besoin de timelines, gold/xp par minute, données très granulaires
```

---

## 8. Architecture révisée du projet

```
lol-analyser/
├── backend/                          # Cloudflare Workers (Hono + TypeScript)
│   ├── wrangler.toml                 # Config Cloudflare
│   ├── package.json
│   ├── tsconfig.json
│   ├── src/
│   │   ├── index.ts                  # Routes Hono
│   │   ├── routes/
│   │   │   ├── auth.ts               # Apple Sign In verification
│   │   │   ├── game.ts               # POST /game/init, POST /game/analyze
│   │   │   └── user.ts               # GET/PUT /user/profile
│   │   ├── services/
│   │   │   ├── vision.ts             # Claude Vision (extraction TAB)
│   │   │   ├── coach.ts              # Claude coaching (streaming SSE)
│   │   │   ├── opgg.ts               # Client OP.GG MCP
│   │   │   ├── game-data.ts          # DDragon/CDragon (items, champions)
│   │   │   └── cache.ts              # Cloudflare KV cache layer
│   │   ├── prompts/
│   │   │   ├── extraction.ts         # Prompt extraction TAB screen
│   │   │   ├── coaching.ts           # Prompt coaching adaptatif
│   │   │   └── system.ts             # System prompt avec données meta
│   │   ├── types/
│   │   │   ├── game.ts               # Types game, player, analysis
│   │   │   ├── opgg.ts               # Types OP.GG MCP responses
│   │   │   └── coach.ts              # Types coaching output
│   │   └── middleware/
│   │       ├── auth.ts               # JWT verification
│   │       └── rate-limit.ts         # Rate limiting par user
│   └── test/
│       └── *.test.ts
│
├── ios/                              # Swift Package (pas de .xcodeproj)
│   ├── Package.swift                 # SPM config
│   ├── LoLCoach/
│   │   ├── App/
│   │   │   ├── LoLCoachApp.swift
│   │   │   └── AppState.swift        # État global de l'app
│   │   ├── Models/
│   │   │   ├── Player.swift
│   │   │   ├── GameSession.swift     # Le thread de coaching par game
│   │   │   ├── Analysis.swift
│   │   │   └── CoachMessage.swift
│   │   ├── Views/
│   │   │   ├── HomeView.swift        # Accueil : nouvelle game ou historique
│   │   │   ├── SetupView.swift       # Config Riot ID + région (première fois)
│   │   │   ├── CaptureView.swift     # Import photo (PhotosPicker)
│   │   │   ├── GameView.swift        # Vue principale : chat coaching
│   │   │   ├── AnalysisCardView.swift # Carte résumé d'un screenshot
│   │   │   └── HistoryView.swift     # Historique des games
│   │   ├── ViewModels/
│   │   │   ├── GameViewModel.swift   # Gère la session de game
│   │   │   └── HomeViewModel.swift
│   │   ├── Services/
│   │   │   ├── APIClient.swift       # URLSession → backend
│   │   │   ├── SSEClient.swift       # Client Server-Sent Events
│   │   │   ├── ImageProcessor.swift  # Compression, rotation, resize
│   │   │   └── AuthService.swift     # Apple Sign In
│   │   └── Resources/
│   │       └── Assets.xcassets
│   └── Tests/
│
├── PLAN_V2.md                        # Ce document
└── README.md
```

---

## 9. Endpoints API

```
POST /auth/apple          # Vérifier le token Apple Sign In → retourne JWT
POST /game/init           # Envoyer 1er screenshot → analyse + fetch données + plan initial (SSE)
POST /game/analyze        # Envoyer screenshot suivant → coaching adaptatif (SSE)
GET  /game/:id            # Récupérer une session de game complète
GET  /user/profile        # Profil utilisateur (Riot ID, région, stats d'usage)
PUT  /user/profile        # Mettre à jour le profil
GET  /user/history        # Historique des games analysées
GET  /health              # Health check
```

**POST /game/init** (le plus complexe) :
```
Request:
  - image: multipart/form-data (JPEG, max 5MB)
  - riot_id: string (ex: "PlayerName#EUW")
  - region: string (ex: "euw1")

Response: SSE stream
  event: extraction
  data: { ... JSON extrait du TAB screen ... }

  event: players
  data: { ... données enrichies des 10 joueurs ... }

  event: coaching
  data: { "text": "chunk de texte du coaching..." }
  data: { "text": "...suite..." }
  ...

  event: done
  data: { "game_id": "uuid", "phase": "early" }
```

---

## 10. Phases d'implémentation révisées

### Phase 0 : Proof of Concept (1-2 jours)
- [ ] Script standalone : envoyer un screenshot TAB à Claude Vision
- [ ] Vérifier la qualité de l'extraction (noms, KDA, items)
- [ ] Tester le prompt coaching avec des données hardcodées
- [ ] Valider que la qualité est suffisante pour continuer

### Phase 1 : Backend MVP (3-5 jours)
- [ ] Setup Hono + Cloudflare Workers
- [ ] Service Claude Vision (extraction)
- [ ] Service OP.GG MCP (données joueurs + meta)
- [ ] Service DDragon (données statiques)
- [ ] Endpoint /game/init avec SSE streaming
- [ ] Endpoint /game/analyze
- [ ] Cache KV pour les données statiques

### Phase 2 : iOS App MVP (5-7 jours)
- [ ] Projet Swift/SwiftUI
- [ ] Écran setup (Riot ID + région)
- [ ] Import photo (PhotosPicker)
- [ ] Service API + SSE Client
- [ ] Vue Game (chat coaching avec streaming)
- [ ] Compression image (ImageProcessor)

### Phase 3 : Game Session complète (3-5 jours)
- [ ] Thread conversationnel (contexte persistant par game)
- [ ] Multiple screenshots par game
- [ ] Adaptation par phase de jeu
- [ ] SwiftData : persistance locale des sessions
- [ ] Historique des games

### Phase 4 : Auth + Monetization (3-5 jours)
- [ ] Apple Sign In
- [ ] JWT backend
- [ ] Rate limiting par user
- [ ] StoreKit 2 (In-App Purchase)
- [ ] Quotas free/premium

### Phase 5 : Polish + Launch (5-7 jours)
- [ ] UI/UX polish (animations, loading states)
- [ ] Error handling complet
- [ ] Onboarding
- [ ] TestFlight beta
- [ ] App Store submission
---

## 11. Risques et décisions ouvertes

| Décision | Options | Recommandation | Pourquoi |
|----------|---------|---------------|----------|
| Backend runtime | Cloudflare Workers vs Railway vs AWS Lambda | **Cloudflare Workers** | Free tier, 0ms cold start, R2 inclus, DDoS inclus |
| IA extraction | Haiku vs Sonnet | **Haiku 4.5** | Suffisant pour OCR, 3-5x moins cher |
| IA coaching | Sonnet vs Opus | **Sonnet 4.5** | Bon rapport qualité/prix, streaming rapide |
| Auth | Apple Sign In vs Email/Password | **Apple Sign In** | Obligatoire iOS si compte, zéro friction |
| Data joueurs | ~~Riot API~~ vs OP.GG MCP | **OP.GG MCP uniquement** | Couvre tout, gratuit, pas de clé, pas de rate limit |
| Stockage local | SwiftData vs UserDefaults | **SwiftData** | Données structurées (sessions, analyses), iOS 17+ |
| Image format | Base64 vs Multipart | **Multipart** | 30% plus léger, standard HTTP |
| Streaming | SSE vs WebSocket | **SSE** | Plus simple, unidirectionnel suffit, reconnexion native |
