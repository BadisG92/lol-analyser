import SwiftUI
import SwiftData

// MARK: - HistoryView

/// Lists all past game sessions stored in SwiftData.
///
/// Sessions are grouped by date and displayed with DDragon champion icons,
/// role badges, team-colored borders, game stats, and analysis counts.
/// Tapping a row navigates to `GameView` in review mode.
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
            DesignTokens.bgPrimary
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
            // Stats banner
            Section {
                statsHeader
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
            }

            ForEach(groupedByDate, id: \.key) { group in
                Section {
                    ForEach(group.sessions) { session in
                        NavigationLink {
                            GameView(session: session, isReview: true)
                        } label: {
                            HistoryRow(session: session)
                        }
                        .listRowBackground(DesignTokens.bgSecondary)
                    }
                    .onDelete { offsets in
                        deleteSessions(in: group.sessions, at: offsets)
                    }
                } header: {
                    Text(group.key)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignTokens.gold)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 16) {
            statPill(
                value: "\(allSessions.count)",
                label: "Games",
                icon: "gamecontroller.fill",
                color: DesignTokens.blue
            )

            statPill(
                value: "\(totalAnalyses)",
                label: "Analyses",
                icon: "camera.fill",
                color: DesignTokens.gold
            )

            statPill(
                value: uniqueChampionCount,
                label: "Champions",
                icon: "person.2.fill",
                color: DesignTokens.phaseEarly
            )
        }
        .padding(.horizontal, 4)
    }

    private func statPill(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(DesignTokens.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var totalAnalyses: Int {
        allSessions.reduce(0) { $0 + $1.analyses.count }
    }

    private var uniqueChampionCount: String {
        let champions = Set(allSessions.map(\.playerChampion))
        return "\(champions.count)"
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(DesignTokens.muted.opacity(0.08))
                    .frame(width: 120, height: 120)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignTokens.muted, DesignTokens.muted.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Aucun historique")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Vos analyses de games apparaitront ici.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
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

/// A detailed row for the history list, showing DDragon champion icon with
/// team-colored border, role badge, game stats (score, time, phase), and metadata.
struct HistoryRow: View {
    let session: GameSession

    var body: some View {
        HStack(spacing: 14) {
            // Champion portrait from DDragon with team border
            championPortrait

            // Info column
            VStack(alignment: .leading, spacing: 5) {
                // Champion name + role badge
                HStack(spacing: 6) {
                    Text(session.playerChampion)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    RoleBadge(role: session.playerRole, compact: true)
                }

                // Game stats row
                gameStatsRow
            }

            Spacer()

            // Right side: time + analysis count
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
                .foregroundStyle(DesignTokens.gold)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Champion Portrait

    private var championPortrait: some View {
        DDragonImage(
            url: URL(string: "https://ddragon.leagueoflegends.com/cdn/15.3.1/img/champion/\(session.playerChampion).png"),
            size: 50
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    teamBorderGradient,
                    lineWidth: 2.5
                )
        }
    }

    private var teamBorderGradient: LinearGradient {
        let color = DesignTokens.teamColor(for: session.playerTeam)
        return LinearGradient(
            colors: [color.opacity(0.9), color.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Game Stats Row

    @ViewBuilder
    private var gameStatsRow: some View {
        if let latest = session.latestAnalysis {
            HStack(spacing: 10) {
                // Game time
                HStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(Int(latest.extraction.gameTimeMinutes))min")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                // Team score with colors
                HStack(spacing: 2) {
                    Text("\(latest.extraction.blueTeam.kills)")
                        .foregroundStyle(DesignTokens.teamBlue)
                    Text("-")
                        .foregroundStyle(DesignTokens.muted)
                    Text("\(latest.extraction.redTeam.kills)")
                        .foregroundStyle(DesignTokens.teamRed)
                }
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()

                // Phase indicator
                Text(latest.gamePhase.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(DesignTokens.phaseColor(for: latest.gamePhase))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DesignTokens.phaseColor(for: latest.gamePhase).opacity(0.12))
                    .clipShape(Capsule())
            }
        } else {
            Text("Pas de donnees")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environment(AppState())
    }
}
