# LoL AI Coach - Plan d'implémentation iOS

## Vision du produit

Application iOS qui agit comme un **coach IA personnel** pour League of Legends.
L'utilisateur prend une photo de son écran TAB en pleine game avec son téléphone, et l'app analyse tout : les joueurs, leurs historiques, la draft, l'état de la game, et propose un plan de jeu complet.

**Différenciateur clé** : Aucune app similaire n'existe sur iOS. Blitz, Mobalytics, Porofessor sont tous desktop uniquement. OP.GG a une app iOS mais ne fait que du stat tracking, pas du coaching.

---

## Conformité Riot Games (TOS)

### Ce qui est autorisé
- Analyse post-game et stat tracking
- Outils de coaching
- Apps utilisant l'API Riot officielle
- Apps qui n'interagissent pas avec le client de jeu

### Zone grise
- L'analyse de screenshot **pendant** une game est dans une zone grise. Riot dit qu'ils ne veulent pas d'apps qui "draw conclusions for you during gameplay"
- MAIS : prendre une photo d'un écran avec un téléphone externe ≠ overlay/injection
- L'app ne touche jamais au client LoL, ne lit pas la mémoire, n'injecte rien
- C'est l'équivalent de demander conseil à un ami qui regarde ton écran

### Positionnement recommandé
- Positionner l'app comme un **outil d'apprentissage/coaching** et pas un "cheat tool"
- L'analyse prend quelques secondes (pas instantané comme un overlay)
- Encourager l'utilisation entre les games ou pendant les temps morts

---

## Architecture technique

### Stack technologique

```
┌─────────────────────────────────────────────┐
│              iOS App (SwiftUI)               │
│  - Camera/Photo capture                      │
│  - UI pour afficher l'analyse                │
│  - Vision framework (OCR local optionnel)    │
│  - Stockage local (SwiftData)                │
└──────────────────┬──────────────────────────┘
                   │ HTTPS
┌──────────────────▼──────────────────────────┐
│           Backend Server (Node.js)           │
│  - Proxy sécurisé pour les API keys          │
│  - API Claude/OpenAI Vision pour analyse img │
│  - API Riot Games pour data joueurs          │
│  - Cache Redis pour limiter les appels API   │
│  - Logique de coaching / prompts IA          │
└──────────────────┬──────────────────────────┘
                   │
        ┌──────────┼──────────┐
        ▼          ▼          ▼
   Riot API    Claude API   OP.GG MCP
```

### Pourquoi un backend est obligatoire
1. **Sécurité** : Impossible d'embarquer des API keys (Riot, Claude) dans une app iOS distribuée
2. **Rate limiting Riot** : Le backend centralise et contrôle les appels
3. **Logique complexe** : Orchestration de multiples API calls + construction du prompt IA
4. **Cache** : Évite de re-fetcher les mêmes données joueur

---

## Structure du projet iOS

```
lol-analyser/
├── ios/
│   ├── LoLCoach.xcodeproj
│   ├── LoLCoach/
│   │   ├── App/
│   │   │   ├── LoLCoachApp.swift          # Point d'entrée
│   │   │   └── ContentView.swift           # Navigation principale
│   │   ├── Models/
│   │   │   ├── Player.swift                # Modèle joueur
│   │   │   ├── GameAnalysis.swift          # Résultat d'analyse
│   │   │   ├── CoachingPlan.swift          # Plan de jeu
│   │   │   └── Champion.swift              # Data champion
│   │   ├── Views/
│   │   │   ├── Home/
│   │   │   │   └── HomeView.swift          # Écran d'accueil
│   │   │   ├── Capture/
│   │   │   │   ├── CaptureView.swift       # Camera + import photo
│   │   │   │   └── CameraRepresentable.swift
│   │   │   ├── Analysis/
│   │   │   │   ├── AnalysisView.swift      # Résultat d'analyse
│   │   │   │   ├── PlayerCardView.swift    # Carte joueur
│   │   │   │   ├── TeamCompView.swift      # Vue composition
│   │   │   │   └── CoachingView.swift      # Recommandations
│   │   │   ├── History/
│   │   │   │   └── HistoryView.swift       # Historique analyses
│   │   │   └── Settings/
│   │   │       └── SettingsView.swift       # Config utilisateur
│   │   ├── ViewModels/
│   │   │   ├── CaptureViewModel.swift
│   │   │   ├── AnalysisViewModel.swift
│   │   │   └── HistoryViewModel.swift
│   │   ├── Services/
│   │   │   ├── APIService.swift            # Calls vers le backend
│   │   │   ├── ImageService.swift          # Traitement image
│   │   │   └── StorageService.swift        # Persistance locale
│   │   ├── Utils/
│   │   │   ├── Constants.swift
│   │   │   └── Extensions.swift
│   │   └── Resources/
│   │       ├── Assets.xcassets
│   │       └── Info.plist
│   └── LoLCoachTests/
├── backend/
│   ├── package.json
│   ├── src/
│   │   ├── index.ts                        # Express server
│   │   ├── routes/
│   │   │   ├── analyze.ts                  # POST /analyze (image)
│   │   │   └── player.ts                   # GET /player/:riotId
│   │   ├── services/
│   │   │   ├── visionAnalyzer.ts           # Analyse image via Claude
│   │   │   ├── riotApi.ts                  # Client Riot API
│   │   │   ├── coachEngine.ts              # Moteur de coaching
│   │   │   └── patchData.ts               # Data du patch actuel
│   │   ├── prompts/
│   │   │   ├── screenAnalysis.ts           # Prompt extraction TAB
│   │   │   └── coaching.ts                 # Prompt coaching
│   │   └── types/
│   │       └── index.ts
│   └── tsconfig.json
└── README.md
```

---

## Flux utilisateur détaillé

### Flow principal

```
1. OUVERTURE APP
   └─> Écran d'accueil avec bouton "Analyser une game"
   └─> Option : "Qui es-tu ?" → l'utilisateur entre son Riot ID (gameName#tagLine)
       → sauvegardé localement pour les futures analyses

2. CAPTURE D'IMAGE
   └─> Choix : Prendre une photo (caméra) OU Importer depuis la galerie
   └─> L'utilisateur prend en photo son écran PC montrant le TAB screen
   └─> Preview de l'image avec bouton "Analyser"

3. ENVOI AU BACKEND
   └─> L'image est compressée (JPEG quality 0.8) et envoyée en base64
   └─> Le Riot ID de l'utilisateur est envoyé aussi
   └─> Affichage d'un loading avec des tips LoL pendant l'attente

4. ANALYSE BACKEND (le coeur du système)

   Étape 4a - Extraction visuelle (Claude Vision)
   └─> Envoi de l'image à Claude avec un prompt structuré
   └─> Extraction : 10 noms de joueurs, champions, KDA, CS, items, levels
   └─> Identification de l'équipe de l'utilisateur (basé sur son Riot ID)
   └─> Estimation du temps de game

   Étape 4b - Enrichissement données (Riot API)
   └─> Pour chaque joueur identifié :
       ├─> Lookup Riot ID → PUUID (ACCOUNT-V1)
       ├─> Ranked info : tier, LP, win rate (LEAGUE-V4)
       ├─> Match history récent : 10 derniers matchs (MATCH-V5)
       ├─> Champion mastery & win rate sur le champion joué
       └─> Tendances : early game stats, CS/min moyen, KDA moyen

   Étape 4c - Analyse IA coaching (Claude)
   └─> Envoi de TOUTES les données combinées à Claude
   └─> Prompt de coaching structuré (voir section Prompts)
   └─> Génération du plan de jeu

5. AFFICHAGE RÉSULTATS
   └─> Résumé de la game (score, gold estimé, temps)
   └─> Cartes joueurs (les 10) avec stats enrichies
   └─> Points forts / faibles de chaque équipe
   └─> Analyse de draft
   └─> PLAN DE JEU :
       ├─> Win conditions identifiées
       ├─> Comment jouer les 5 prochaines minutes
       ├─> Sur qui focus en teamfight
       ├─> Build recommandé pour le reste de la game
       ├─> Macro conseils (split push, teamfight, objectifs)
       └─> Erreurs à éviter

6. SAUVEGARDE
   └─> L'analyse est sauvegardée localement (SwiftData)
   └─> Accessible dans l'historique pour review
```

---

## Prompts IA (coeur de la valeur)

### Prompt 1 : Extraction du TAB screen

```
Tu es un expert en analyse d'images de League of Legends.
Analyse cette capture d'écran du scoreboard (TAB) en jeu.

Extrais les informations suivantes en JSON structuré :
- game_time: temps de jeu estimé
- blue_team: tableau de 5 joueurs
- red_team: tableau de 5 joueurs

Pour chaque joueur :
- summoner_name: nom du joueur (Riot ID)
- champion: nom du champion joué
- level: niveau du champion
- kda: { kills, deaths, assists }
- cs: creep score
- items: liste des items visibles (noms)
- summoner_spells: [spell1, spell2]
- role: top/jungle/mid/adc/support (déduit du champion et position)

Si une information n'est pas lisible, indique "unknown".
Sois précis sur les noms de champions et items.
```

### Prompt 2 : Coaching complet

```
Tu es un coach Diamond+ de League of Legends avec 10 ans d'expérience.
Tu analyses la situation actuelle d'une game en cours pour aider un joueur.

CONTEXTE DE LA GAME :
{données extraites du TAB + données Riot API enrichies}

LE JOUEUR QUE TU COACHES :
- Nom : {riot_id}
- Champion : {champion}
- Role : {role}
- Stats actuelles : {kda, cs, level, items}

DONNÉES DES JOUEURS (historique récent) :
{pour chaque joueur : rank, win rate, champion mastery, tendances}

PATCH ACTUEL : {patch_number}
META ACTUELLE : {infos meta pertinentes}

Fournis une analyse complète en français :

1. ÉTAT DE LA GAME
   - Quelle équipe est en avance et pourquoi
   - Gold difference estimée
   - Power spikes à venir

2. ANALYSE DE DRAFT
   - Forces et faiblesses de chaque composition
   - Win condition de chaque équipe
   - Synergies et combos à exploiter

3. ANALYSE DES JOUEURS ADVERSES
   - Joueurs dangereux (basé sur leur historique)
   - Joueurs exploitables (faible win rate, autofilled, etc.)
   - Tendances de jeu (agressif, passif, etc.)

4. PLAN DE JEU RECOMMANDÉ
   - Macro : split push, teamfight, picks, objectifs
   - Les 5 prochaines minutes : quoi faire concrètement
   - Itemisation : prochain item recommandé et pourquoi
   - Focus en teamfight : qui cibler, qui éviter
   - Warding : où warder pour la situation actuelle

5. ERREURS À ÉVITER
   - Pièges basés sur la compo adverse
   - Mauvais fights à ne pas prendre
   - Erreurs communes sur ton champion dans cette situation

Sois direct, concret et actionnable. Pas de blabla théorique.
```

---

## Étapes d'implémentation (ordre de développement)

### Phase 1 : Fondations (MVP Backend)
1. Initialiser le projet Node.js/TypeScript pour le backend
2. Implémenter le service Claude Vision (analyse d'image)
3. Implémenter le client Riot API (lookup joueur, match history)
4. Créer l'endpoint POST `/api/analyze`
5. Tester avec des screenshots réels du TAB screen

### Phase 2 : App iOS - Structure de base
6. Créer le projet Xcode avec SwiftUI
7. Implémenter la navigation (TabView ou NavigationStack)
8. Créer l'écran de configuration (saisie Riot ID)
9. Implémenter la capture photo (caméra + galerie)
10. Créer le service API (communication avec le backend)

### Phase 3 : App iOS - Affichage des résultats
11. Designer et implémenter les vues d'analyse
12. Cartes joueurs avec stats
13. Vue plan de jeu / coaching
14. Animations de loading
15. Gestion d'erreurs et edge cases

### Phase 4 : Persistance et polish
16. SwiftData pour l'historique des analyses
17. Vue historique
18. Optimisations (compression image, cache)
19. Dark mode et thème LoL
20. Onboarding / tutorial

### Phase 5 : Production
21. Déploiement backend (Railway / Fly.io / AWS)
22. Demande de clé API Riot production
23. TestFlight et beta testing
24. Soumission App Store

---

## Risques et mitigations

| Risque | Impact | Mitigation |
|--------|--------|------------|
| OCR imprécis sur screenshots de qualité variable | Analyse incorrecte | Utiliser Claude Vision (très bon sur le texte dans les images) + demander à l'utilisateur de confirmer |
| Rate limiting Riot API (dev key = 100 req/2min) | Lenteur pour enrichir 10 joueurs | Cache agressif + batch les requêtes + clé production |
| Riot interdit l'app | App retirée | Positionnement coaching/éducatif, pas d'overlay, pas de temps réel |
| Coût API Claude élevé | Non rentable | Optimiser les prompts, utiliser Haiku pour l'extraction et Sonnet pour le coaching |
| Latence totale élevée (image → analyse → enrichissement → coaching) | Mauvaise UX | Paralléliser les appels Riot API, streaming de la réponse coaching |

---

## Estimation des coûts API (par analyse)

| Service | Appel | Coût estimé |
|---------|-------|-------------|
| Claude Vision (extraction) | 1 image + prompt | ~$0.01-0.03 |
| Claude (coaching) | Gros prompt texte | ~$0.02-0.05 |
| Riot API | ~20-30 calls | Gratuit |
| **Total par analyse** | | **~$0.03-0.08** |

---

## Décisions techniques à prendre

1. **Claude vs OpenAI** pour l'analyse vision → Recommandation : Claude (meilleur sur le texte structuré dans les images)
2. **Backend hébergement** → Railway ou Fly.io pour le MVP, AWS/GCP pour la production
3. **iOS minimum** → iOS 17+ (pour @Observable, SwiftData)
4. **Modèle économique** → Freemium (X analyses gratuites/jour, abonnement pour illimité)
5. **Langue de l'app** → Français d'abord, puis anglais
