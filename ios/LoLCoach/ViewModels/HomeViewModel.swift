import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class HomeViewModel {
    var recentSessions: [GameSession] = []

    func loadSessions(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<GameSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        recentSessions = (try? modelContext.fetch(descriptor)) ?? []
    }
}
