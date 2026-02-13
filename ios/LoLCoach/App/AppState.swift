import Foundation
import Observation
import SwiftData

// MARK: - AppState

/// Global application state using the @Observable macro (iOS 17+).
///
/// Holds the user's Riot profile (persisted in UserDefaults),
/// the active game session, and recent session history loaded from SwiftData.
@Observable
@MainActor
final class AppState {

    // MARK: - Persisted Profile

    /// The player's Riot ID (e.g. "Player#EUW").
    /// Automatically saved to UserDefaults on every change.
    var riotId: String {
        didSet { UserDefaults.standard.set(riotId, forKey: Keys.riotId) }
    }

    /// The player's server region.
    /// Automatically saved to UserDefaults on every change.
    var region: Region {
        didSet { UserDefaults.standard.set(region.rawValue, forKey: Keys.region) }
    }

    // MARK: - Computed

    /// `true` once the player has entered a valid Riot ID (must contain '#').
    var isSetupComplete: Bool {
        !riotId.isEmpty && riotId.contains("#")
    }

    // MARK: - Session State

    /// The currently active game session (nil when no game is in progress).
    var currentSession: GameSession?

    /// Recent sessions loaded from the SwiftData store, newest first.
    var recentSessions: [GameSession] = []

    // MARK: - Init

    init() {
        self.riotId = UserDefaults.standard.string(forKey: Keys.riotId) ?? ""
        let regionRaw = UserDefaults.standard.string(forKey: Keys.region) ?? Region.euw1.rawValue
        self.region = Region(rawValue: regionRaw) ?? .euw1
    }

    // MARK: - Methods

    /// Saves the player's profile information.
    ///
    /// - Parameters:
    ///   - riotId: The Riot ID string (e.g. "Player#EUW").
    ///   - region: The server region.
    func saveProfile(riotId: String, region: Region) {
        self.riotId = riotId
        self.region = region
    }

    /// Loads recent game sessions from SwiftData, sorted by creation date (newest first).
    ///
    /// - Parameter context: The SwiftData `ModelContext` to query.
    func loadRecentSessions(context: ModelContext) {
        let descriptor = FetchDescriptor<GameSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            recentSessions = try context.fetch(descriptor)
        } catch {
            recentSessions = []
        }
    }

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let riotId = "riotId"
        static let region = "region"
    }
}
