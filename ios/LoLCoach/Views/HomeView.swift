import SwiftUI
import SwiftData

// MARK: - HomeView

/// Main landing screen after setup.
///
/// Shows the player's Riot ID with a rank/region badge, a prominent
/// "Nouvelle Analyse" GlowButton, and a list of recent game sessions
/// with DDragon champion icons, role badges, and team-colored stats.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var showSetup = false
    @State private var navigateToCapture = false
    @State private var gradientPhase: CGFloat = 0

    var body: some View {
        ZStack {
            DesignTokens.bgGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    ctaButton

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
                        .foregroundStyle(DesignTokens.gold)
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
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                gradientPhase = 1
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Riot ID prominent display
            HStack(alignment: .center, spacing: 12) {
                // Summoner icon placeholder
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.gold.opacity(0.3), DesignTokens.gold.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DesignTokens.gold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Invocateur")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Text(appState.riotId)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DesignTokens.gold, DesignTokens.goldLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Spacer()

                // Region badge
                regionBadge
            }
        }
        .padding(18)
        .background(DesignTokens.bgCard.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.gold.opacity(0.6),
                            DesignTokens.blue.opacity(0.3),
                            DesignTokens.gold.opacity(0.1),
                            DesignTokens.blue.opacity(0.4),
                            DesignTokens.gold.opacity(0.6)
                        ]),
                        center: .center,
                        angle: .degrees(gradientPhase * 360)
                    ),
                    lineWidth: 1.5
                )
        }
    }

    private var regionBadge: some View {
        VStack(spacing: 2) {
            Image(systemName: "globe")
                .font(.caption2)
                .foregroundStyle(DesignTokens.blue)

            Text(regionShortName(appState.region))
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(DesignTokens.bgCardHover)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        GlowButton(title: "Nouvelle Analyse", icon: "camera.viewfinder") {
            navigateToCapture = true
        }
    }

    // MARK: - Recent Games

    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Games Recentes")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                NavigationLink {
                    HistoryView()
                } label: {
                    HStack(spacing: 4) {
                        Text("Tout voir")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(DesignTokens.gold)
                }
            }

            ForEach(appState.recentSessions.prefix(5)) { session in
                NavigationLink {
                    GameView(session: session, isReview: true)
                } label: {
                    HomeHistoryItem(session: session)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(DesignTokens.muted.opacity(0.1))
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(DesignTokens.muted.opacity(0.05))
                    .frame(width: 130, height: 130)

                Image(systemName: "sword.circle")
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
                Text("Aucune game analysee")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Prenez un screenshot TAB pendant votre game et laissez le coach vous guider.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 48)
    }

    // MARK: - Helpers

    private func regionShortName(_ region: Region) -> String {
        switch region {
        case .euw1: "EUW"
        case .na1: "NA"
        case .kr: "KR"
        case .eun1: "EUNE"
        case .br1: "BR"
        case .jp1: "JP"
        case .la1: "LAN"
        case .la2: "LAS"
        case .oc1: "OCE"
        case .tr1: "TR"
        case .ru: "RU"
        case .ph2: "PH"
        case .sg2: "SG"
        case .th2: "TH"
        case .tw2: "TW"
        case .vn2: "VN"
        }
    }
}

// MARK: - HomeHistoryItem

/// Compact row for recent games on the home screen.
/// Displays DDragon champion icon, role badge, game stats with team colors,
/// relative date, and analysis count.
struct HomeHistoryItem: View {
    let session: GameSession

    var body: some View {
        HStack(spacing: 14) {
            // Champion icon from DDragon
            championIcon

            // Champion name + role + stats
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(session.playerChampion)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    RoleBadge(role: session.playerRole, compact: true)
                }

                gameSummaryLine
            }

            Spacer()

            // Right side: date + analysis count
            VStack(alignment: .trailing, spacing: 6) {
                Text(session.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 3) {
                    Image(systemName: "camera.fill")
                        .font(.caption2)
                    Text("\(session.analyses.count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(DesignTokens.gold.opacity(0.8))
            }
        }
        .padding(14)
        .background(DesignTokens.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    DesignTokens.teamColor(for: session.playerTeam).opacity(0.15),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Champion Icon

    private var championIcon: some View {
        DDragonImage(
            url: DesignTokens.championIconURL(session.playerChampion),
            size: 44
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    DesignTokens.teamColor(for: session.playerTeam).opacity(0.6),
                    lineWidth: 2
                )
        }
    }

    // MARK: - Game Summary Line

    @ViewBuilder
    private var gameSummaryLine: some View {
        if let latest = session.latestAnalysis {
            HStack(spacing: 10) {
                // Time
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

                // Player KDA if available
                if let player = session.playerData {
                    KDAText(
                        kills: player.kills,
                        deaths: player.deaths,
                        assists: player.assists,
                        font: .caption
                    )
                }
            }
        } else {
            Text(session.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(AppState())
    }
}
