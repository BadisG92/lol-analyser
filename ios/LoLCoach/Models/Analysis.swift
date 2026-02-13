import Foundation

struct TeamExtracted: Codable {
    let kills: Int
    let towersDestroyed: Int
    let drakes: [String]
    let grubs: Int
    let herald: Bool
    let baron: Bool
    let players: [Player]

    enum CodingKeys: String, CodingKey {
        case kills, drakes, grubs, herald, baron, players
        case towersDestroyed = "towers_destroyed"
    }
}

struct TabScreenExtraction: Codable {
    let gameTimeMinutes: Double
    let blueTeam: TeamExtracted
    let redTeam: TeamExtracted
    let minimapObservations: String
    let additionalObservations: String

    enum CodingKeys: String, CodingKey {
        case gameTimeMinutes = "game_time_minutes"
        case blueTeam = "blue_team"
        case redTeam = "red_team"
        case minimapObservations = "minimap_observations"
        case additionalObservations = "additional_observations"
    }

    func team(for side: Team) -> TeamExtracted {
        side == .blue ? blueTeam : redTeam
    }

    func opponent(of side: Team) -> TeamExtracted {
        side == .blue ? redTeam : blueTeam
    }
}

struct ScreenshotAnalysis: Codable, Identifiable {
    let id: String
    let timestamp: Double
    let extraction: TabScreenExtraction
    let coaching: String
    let gamePhase: GamePhase

    enum CodingKeys: String, CodingKey {
        case id, timestamp, extraction, coaching
        case gamePhase = "game_phase"
    }
}
