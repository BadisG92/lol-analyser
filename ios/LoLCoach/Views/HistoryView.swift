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

    @Query(sort: \GameSessionRecord.createdAt, order: .reverse)
    private var allRecords: [GameSessionRecord]

    @State private var searchText = ""

    private var filteredRecords: [GameSessionRecord] {
        if searchText.isEmpty {
            return allRecords
        }
        return allRecords.filter { record in
            record.playerChampion.localizedCaseInsensitiveContains(searchText)
                || record.riotId.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color(hex: 0x0A0E1A)
                .ignoresSafeArea()

            if allRecords.isEmpty {
                emptyState
            } else {
                recordsList
            }
        }
        .navigationTitle("Historique")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Rechercher un champion...")
        .preferredColorScheme(.dark)
    }

    // MARK: - Records List

    private var recordsList: some View {
        List {
            ForEach(groupedByDate, id: \.key) { group in
                Section {
                    ForEach(group.records, id: \.sessionId) { record in
                        NavigationLink {
                            GameView(record: record, isReview: true)
                        } label: {
                            HistoryRow(record: record)
                        }
                        .listRowBackground(Color(hex: 0x111827))
                    }
                    .onDelete { offsets in
                        deleteRecords(in: group.records, at: offsets)
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
        let records: [GameSessionRecord]
    }

    private var groupedByDate: [DateGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredRecords) { record -> String in
            if calendar.isDateInToday(record.createdAt) {
                return "Aujourd'hui"
            } else if calendar.isDateInYesterday(record.createdAt) {
                return "Hier"
            } else {
                return record.createdAt.formatted(.dateTime.day().month(.wide))
            }
        }

        return grouped
            .map { DateGroup(key: $0.key, records: $0.value) }
            .sorted { g1, g2 in
                let d1 = g1.records.first?.createdAt ?? .distantPast
                let d2 = g2.records.first?.createdAt ?? .distantPast
                return d1 > d2
            }
    }

    // MARK: - Actions

    private func deleteRecords(in records: [GameSessionRecord], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
        try? modelContext.save()
    }
}

// MARK: - HistoryRow

/// A detailed row for the history list, showing champion, role, game stats, and metadata.
struct HistoryRow: View {
    let record: GameSessionRecord

    var body: some View {
        HStack(spacing: 14) {
            // Champion avatar
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(teamGradient)
                    .frame(width: 50, height: 50)

                Text(String(record.playerChampion.prefix(2)).uppercased())
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(record.playerChampion)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    if let role = Role(rawValue: record.playerRole) {
                        Text(role.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: 0x1E293B))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    if let phase = GamePhase(rawValue: record.gamePhase) {
                        Text(phase.displayName)
                            .font(.caption2)
                            .foregroundStyle(phaseColor)
                    }

                    if !record.coachingSummary.isEmpty {
                        Text(record.coachingSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Right info
            VStack(alignment: .trailing, spacing: 6) {
                Text(record.createdAt.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 3) {
                    Image(systemName: "camera.fill")
                        .font(.caption2)
                    Text("\(record.analysisCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color(hex: 0xC89B3C))
            }
        }
        .padding(.vertical, 4)
    }

    private var teamGradient: LinearGradient {
        let colors: [Color] = record.playerTeam == "blue"
            ? [Color(hex: 0x0A5CA8), Color(hex: 0x0D3F73)]
            : [Color(hex: 0x9B2C2C), Color(hex: 0x742020)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var phaseColor: Color {
        switch record.gamePhase {
        case "early": Color(hex: 0x22C55E)
        case "mid": Color(hex: 0xF59E0B)
        case "late": Color(hex: 0xEF4444)
        default: Color(hex: 0x3B4A6B)
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environment(AppState())
    }
}
