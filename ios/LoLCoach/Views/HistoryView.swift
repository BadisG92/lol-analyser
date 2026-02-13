import SwiftUI
import SwiftData

// MARK: - HistoryView

/// Lists all past game sessions stored in SwiftData.
///
/// Sessions are grouped by date and displayed with champion, role, phase,
/// and analysis count. Tapping a row navigates to `GameView` in review mode.
/// Supports swipe-to-delete and a search bar to filter by champion name.
struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \GameSession.createdAt, order: .reverse)
    private var allSessions: [GameSession]

    @State private var searchText = ""

    private var filteredSessions: [GameSession] {
        if searchText.isEmpty {
            return allSessions
        }
        return allSessions.filter { session in
            session.playerChampion.localizedCaseInsensitiveContains(searchText)
                || session.riotId.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color(hex: 0x0A0E1A)
                .ignoresSafeArea()

            if allSessions.isEmpty {
                emptyState
            } else {
                sessionsList
            }
        }
        .navigationTitle("Historique")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Rechercher un champion...")
        .preferredColorScheme(.dark)
    }

    // MARK: - Sessions List

    private var sessionsList: some View {
        List {
            ForEach(groupedByDate, id: \.key) { group in
                Section {
                    ForEach(group.sessions) { session in
                        NavigationLink {
                            GameView(session: session, isReview: true)
                        } label: {
                            HistoryRow(session: session)
                        }
                        .listRowBackground(Color(hex: 0x111827))
                    }
                    .onDelete { offsets in
                        deleteSessions(in: group.sessions, at: offsets)
                    }
                } header: {
                    Text(group.key)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: 0xC89B3C))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: 0x3B4A6B))

            Text("Aucun historique")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Vos analyses de games apparaitront ici.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Grouping

    private struct DateGroup {
        let key: String
        let sessions: [GameSession]
    }

    private var groupedByDate: [DateGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSessions) { session -> String in
            if calendar.isDateInToday(session.createdAt) {
                return "Aujourd'hui"
            } else if calendar.isDateInYesterday(session.createdAt) {
                return "Hier"
            } else {
                return session.createdAt.formatted(.dateTime.day().month(.wide))
            }
        }

        return grouped
            .map { DateGroup(key: $0.key, sessions: $0.value) }
            .sorted { g1, g2 in
                let d1 = g1.sessions.first?.createdAt ?? .distantPast
                let d2 = g2.sessions.first?.createdAt ?? .distantPast
                return d1 > d2
            }
    }

    // MARK: - Actions

    private func deleteSessions(in sessions: [GameSession], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
        try? modelContext.save()
    }
}

// MARK: - HistoryRow

/// A detailed row for the history list, showing champion, role, game stats, and metadata.
struct HistoryRow: View {
    let session: GameSession

    var body: some View {
        HStack(spacing: 14) {
            // Champion avatar
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(teamGradient)
                    .frame(width: 50, height: 50)

                Text(String(session.playerChampion.prefix(2)).uppercased())
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(session.playerChampion)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(session.playerRole.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0x1E293B))
                        .clipShape(Capsule())
                }

                HStack(spacing: 12) {
                    // Game time from latest analysis
                    if let latest = session.latestAnalysis {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text("\(Int(latest.extraction.gameTimeMinutes))min")
                                .font(.caption)
                        }

                        // Score
                        HStack(spacing: 3) {
                            Text("\(latest.extraction.blueTeam.kills)")
                                .foregroundStyle(Color(hex: 0x4A9EEF))
                            Text("-")
                            Text("\(latest.extraction.redTeam.kills)")
                                .foregroundStyle(Color(hex: 0xEF4444))
                        }
                        .font(.caption)
                        .fontWeight(.medium)

                        // Phase
                        Text(latest.gamePhase.displayName)
                            .font(.caption2)
                            .foregroundStyle(phaseColor(for: latest.gamePhase))
                    } else {
                        Text("Pas de donnees")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Right side info
            VStack(alignment: .trailing, spacing: 6) {
                Text(session.createdAt.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 3) {
                    Image(systemName: "camera.fill")
                        .font(.caption2)
                    Text("\(session.analyses.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color(hex: 0xC89B3C))
            }
        }
        .padding(.vertical, 4)
    }

    private var teamGradient: LinearGradient {
        let colors: [Color] = session.playerTeam == .blue
            ? [Color(hex: 0x0A5CA8), Color(hex: 0x0D3F73)]
            : [Color(hex: 0x9B2C2C), Color(hex: 0x742020)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func phaseColor(for phase: GamePhase) -> Color {
        switch phase {
        case .early: Color(hex: 0x22C55E)
        case .mid: Color(hex: 0xF59E0B)
        case .late: Color(hex: 0xEF4444)
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environment(AppState())
    }
}
