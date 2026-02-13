import Foundation
import SwiftData

enum GamePhase: String, Codable, CaseIterable {
    case early, mid, late

    var displayName: String {
        switch self {
        case .early: "Early Game"
        case .mid: "Mid Game"
        case .late: "Late Game"
        }
    }
}

@Model
final class GameSession: Identifiable {
    @Attribute(.unique) var id: String
    var riotId: String
    var regionRaw: String
    var playerTeamRaw: String
    var playerRoleRaw: String
    var playerChampion: String
    var createdAt: Date

    @Attribute(.externalStorage)
    var analysesData: Data?

    init(
        id: String = UUID().uuidString,
        riotId: String,
        region: Region,
        playerTeam: Team,
        playerRole: Role,
        playerChampion: String
    ) {
        self.id = id
        self.riotId = riotId
        self.regionRaw = region.rawValue
        self.playerTeamRaw = playerTeam.rawValue
        self.playerRoleRaw = playerRole.rawValue
        self.playerChampion = playerChampion
        self.createdAt = .now
        self.analysesData = nil
    }

    var region: Region {
        get { Region(rawValue: regionRaw) ?? .euw1 }
        set { regionRaw = newValue.rawValue }
    }

    var playerTeam: Team {
        get { Team(rawValue: playerTeamRaw) ?? .blue }
        set { playerTeamRaw = newValue.rawValue }
    }

    var playerRole: Role {
        get { Role(rawValue: playerRoleRaw) ?? .mid }
        set { playerRoleRaw = newValue.rawValue }
    }

    var analyses: [ScreenshotAnalysis] {
        get {
            guard let data = analysesData else { return [] }
            return (try? JSONDecoder().decode([ScreenshotAnalysis].self, from: data)) ?? []
        }
        set {
            analysesData = try? JSONEncoder().encode(newValue)
        }
    }

    var latestAnalysis: ScreenshotAnalysis? {
        analyses.last
    }

    var currentPhase: GamePhase {
        latestAnalysis?.gamePhase ?? .early
    }

    var playerData: Player? {
        guard let extraction = latestAnalysis?.extraction else { return nil }
        let team = extraction.team(for: playerTeam)
        return team.players.first { $0.estimatedRole == playerRole }
    }

    var opponentData: Player? {
        guard let extraction = latestAnalysis?.extraction else { return nil }
        let enemyTeam = extraction.opponent(of: playerTeam)
        return enemyTeam.players.first { $0.estimatedRole == playerRole }
    }

    func addAnalysis(_ analysis: ScreenshotAnalysis) {
        var current = analyses
        current.append(analysis)
        analyses = current
    }

    var summary: String {
        guard let latest = latestAnalysis else { return "No analysis yet" }
        let ext = latest.extraction
        let allyTeam = ext.team(for: playerTeam)
        let enemyTeam = ext.opponent(of: playerTeam)
        return "\(playerChampion) \(playerRole.displayName) | " +
               "\(Int(ext.gameTimeMinutes))min | " +
               "\(allyTeam.kills)-\(enemyTeam.kills)"
    }
}
