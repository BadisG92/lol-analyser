export type Region = "euw1" | "na1" | "kr" | "eun1" | "br1" | "jp1" | "la1" | "la2" | "oc1" | "tr1" | "ru" | "ph2" | "sg2" | "th2" | "tw2" | "vn2";

export type Role = "top" | "jungle" | "mid" | "adc" | "support";
export type GamePhase = "early" | "mid" | "late";
export type Team = "blue" | "red";

export interface PlayerExtracted {
  name: string;
  champion: string;
  level: number;
  kills: number;
  deaths: number;
  assists: number;
  cs: number;
  items: string[];
  summoner_spells: string[];
  estimated_role: Role;
}

export interface TeamExtracted {
  kills: number;
  towers_destroyed: number;
  drakes: string[];
  grubs: number;
  herald: boolean;
  baron: boolean;
  players: PlayerExtracted[];
}

export interface TabScreenExtraction {
  game_time_minutes: number;
  blue_team: TeamExtracted;
  red_team: TeamExtracted;
  minimap_observations: string;
  additional_observations: string;
}

export interface PlayerEnriched extends PlayerExtracted {
  rank: string;
  win_rate: number;
  games_played: number;
  recent_performance: string;
  is_autofill: boolean;
  champion_mastery: string;
}

export interface GameSession {
  id: string;
  riot_id: string;
  region: Region;
  player_team: Team;
  player_role: Role;
  player_champion: string;
  players_blue: PlayerEnriched[];
  players_red: PlayerEnriched[];
  analyses: ScreenshotAnalysis[];
  created_at: number;
}

export interface ScreenshotAnalysis {
  id: string;
  timestamp: number;
  extraction: TabScreenExtraction;
  coaching: string;
  game_phase: GamePhase;
}

export interface GameInitRequest {
  riot_id: string;
  region: Region;
}
