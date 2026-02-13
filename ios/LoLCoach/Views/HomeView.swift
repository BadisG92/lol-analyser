import SwiftUI
import SwiftData

// MARK: - HomeView

/// Main landing screen after setup.
///
/// Shows the player's Riot ID, a prominent "Nouvelle Analyse" button,
/// and a list of recent game sessions loaded from SwiftData via AppState.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var showSetup = false
    @State private var navigateToCapture = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: 0x0A0E1A), Color(hex: 0x111827)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    newAnalysisButton

                    if appState.recentSessions.isEmpty {
                        emptyStateView
                    } else {
                        recentGamesSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("LoL Coach")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSetup = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(Color(hex: 0xC89B3C))
                }
            }
        }
        .sheet(isPresented: $showSetup) {
            SetupView()
        }
        .navigationDestination(isPresented: $navigateToCapture) {
            CaptureView()
        }
        .onAppear {
            appState.loadRecentSessions(context: modelContext)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Invocateur")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(appState.riotId)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: 0xC89B3C))
            }

            Spacer()

            Text(appState.region.displayName)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: 0x1E293B))
                .clipShape(Capsule())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(hex: 0x1A1F2E).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - New Analysis Button

    private var newAnalysisButton: some View {
        Button {
            navigateToCapture = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.title2)
                Text("Nouvelle Analyse")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x0A5CA8), Color(hex: 0x0D7FD9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: 0x0D7FD9).opacity(0.4), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Games

    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Games Recentes")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                NavigationLink {
                    HistoryView()
                } label: {
                    Text("Tout voir")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: 0xC89B3C))
                }
            }

            ForEach(appState.recentSessions.prefix(5)) { session in
                NavigationLink {
                    GameView(session: session, isReview: true)
                } label: {
                    HistoryListItem(session: session)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sword.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: 0x3B4A6B))

            Text("Aucune game analysee")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Prenez un screenshot TAB pendant votre game et laissez le coach vous guider.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 48)
    }
}

// MARK: - HistoryListItem

/// Compact row showing a past game session.
struct HistoryListItem: View {
    let session: GameSession

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0x1E293B))
                    .frame(width: 48, height: 48)
                Text(String(session.playerChampion.prefix(2)).uppercased())
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: 0xC89B3C))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.playerChampion)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text(session.playerRole.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0x1E293B))
                        .clipShape(Capsule())
                }

                Text(session.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 4) {
                    Image(systemName: "camera.fill")
                        .font(.caption2)
                    Text("\(session.analyses.count)")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(hex: 0x1A1F2E))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(AppState())
    }
}
