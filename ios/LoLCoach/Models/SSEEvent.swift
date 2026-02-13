import Foundation

struct SSEStatus: Codable {
    let step: String
    let message: String
}

struct SSEPlayerInfo: Codable {
    let name: String
    let champion: String
    let role: Role
    let team: Team
}

struct SSEPlayersData: Codable {
    let count: Int
    let message: String
}

struct SSECoachingChunk: Codable {
    let text: String
}

struct SSEDone: Codable {
    let gameId: String
    let phase: GamePhase
    let gameTime: Double

    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case phase
        case gameTime = "game_time"
    }
}

struct SSEError: Codable {
    let message: String
}

enum SSEEvent {
    case status(SSEStatus)
    case extraction(TabScreenExtraction)
    case player(SSEPlayerInfo)
    case playersData(SSEPlayersData)
    case coaching(SSECoachingChunk)
    case done(SSEDone)
    case error(SSEError)

    static func parse(event: String, data: String) -> SSEEvent? {
        guard let jsonData = data.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()

        switch event {
        case "status":
            guard let value = try? decoder.decode(SSEStatus.self, from: jsonData) else { return nil }
            return .status(value)

        case "extraction":
            guard let value = try? decoder.decode(TabScreenExtraction.self, from: jsonData) else { return nil }
            return .extraction(value)

        case "player":
            guard let value = try? decoder.decode(SSEPlayerInfo.self, from: jsonData) else { return nil }
            return .player(value)

        case "players_data":
            guard let value = try? decoder.decode(SSEPlayersData.self, from: jsonData) else { return nil }
            return .playersData(value)

        case "coaching":
            guard let value = try? decoder.decode(SSECoachingChunk.self, from: jsonData) else { return nil }
            return .coaching(value)

        case "done":
            guard let value = try? decoder.decode(SSEDone.self, from: jsonData) else { return nil }
            return .done(value)

        case "error":
            guard let value = try? decoder.decode(SSEError.self, from: jsonData) else { return nil }
            return .error(value)

        default:
            return nil
        }
    }
}
