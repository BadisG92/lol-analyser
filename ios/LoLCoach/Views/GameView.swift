import SwiftUI
import PhotosUI

// MARK: - GameView

/// The main coaching screen, displayed as a chat-like thread.
///
/// In **live mode** (default), the view streams coaching text word by word
/// from `GameViewModel` and allows adding additional screenshots mid-game.
///
/// In **review mode** (when opened from history), it displays all past
/// analyses from a `GameSessionRecord` without streaming.
struct GameView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State var gameViewModel: GameViewModel
    var session: GameSession?
    var isReview: Bool

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedTab: GameTab = .coach

    // MARK: - Tab Enum

    private enum GameTab: String, CaseIterable, Identifiable {
        case coach = "Coach"
        case scoreboard = "Scoreboard"

        var id: String { rawValue }
    }

    // MARK: - Init

    init(
        gameViewModel: GameViewModel = GameViewModel(),
        session: GameSession? = nil,
        isReview: Bool = false
    ) {
        self._gameViewModel = State(initialValue: gameViewModel)
        self.session = session
        self.isReview = isReview
    }

    var body: some View {
        ZStack {
            DesignTokens.bgPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                richHeader

                Divider()
                    .overlay(DesignTokens.bgCardHover)

                tabPicker

                // Content area
                ScrollViewReader { proxy in
                    ScrollView {
                        switch selectedTab {
                        case .coach:
                            LazyVStack(spacing: 16) {
                                if isReview {
                                    reviewContent
                                } else {
                                    liveContent
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            // Extra bottom padding for FAB clearance
                            .padding(.bottom, !isReview && !gameViewModel.isLoading ? 72 : 0)

                        case .scoreboard:
                            scoreboardContent
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                        }
                    }
                    .onChange(of: gameViewModel.coachingText) { _, _ in
                        guard selectedTab == .coach else { return }
                        // Scroll without animation during streaming to avoid
                        // spamming dozens of animation transactions per second.
                        proxy.scrollTo("live-card", anchor: .bottom)
                    }
                    .onChange(of: gameViewModel.analyses.count) { _, _ in
                        guard selectedTab == .coach else { return }
                        if let lastId = gameViewModel.analyses.last?.id {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastId, anchor: .top)
                            }
                        }
                    }
                }
            }

            // Floating action button (FAB) for new screenshot — live mode only
            if !isReview && !gameViewModel.isLoading {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingScreenshotButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationTitle(isReview ? "Historique" : "Coach en direct")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if !isReview && gameViewModel.isLoading {
                ToolbarItem(placement: .topBarTrailing) {
                    ProgressView()
                        .tint(DesignTokens.gold)
                }
            }
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                await handleNewScreenshot(item: newValue)
            }
        }
        .onDisappear {
            if !isReview {
                gameViewModel.cancel()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Rich Header

    private var richHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Champion icon + identity
                championIdentity

                Spacer()

                // Game time + phase
                if let extraction = currentExtraction {
                    gameTimeView(extraction: extraction)
                }
            }

            if let extraction = currentExtraction {
                HStack(spacing: 0) {
                    // Score row
                    scoreRow(extraction: extraction)

                    Spacer()

                    // Analysis count badge
                    analysisCountBadge
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(DesignTokens.bgSecondary)
    }

    @ViewBuilder
    private var championIdentity: some View {
        let championName = resolvedChampionName
        let role = resolvedRole
        let team = resolvedTeam

        HStack(spacing: 10) {
            // Champion icon via DDragonImage
            if let championName, !championName.isEmpty {
                DDragonImage(
                    url: URL(string: "https://ddragon.leagueoflegends.com/cdn/15.3.1/img/champion/\(championName).png"),
                    size: 44
                )
                .overlay {
                    if let team {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(DesignTokens.teamColor(for: team), lineWidth: 2)
                    }
                }
            } else {
                // Placeholder icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignTokens.bgCardHover)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.title3)
                            .foregroundStyle(DesignTokens.muted)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let championName, !championName.isEmpty {
                    Text(championName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else {
                    Text("En attente...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let role {
                    RoleBadge(role: role, compact: false)
                }
            }
        }
    }

    private func gameTimeView(extraction: TabScreenExtraction) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(Int(extraction.gameTimeMinutes)):\(String(format: "%02d", Int(extraction.gameTimeMinutes.truncatingRemainder(dividingBy: 1) * 60)))")
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundStyle(.white)
                .monospacedDigit()

            // Phase badge
            let phase = currentPhase
            Text(phase.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(DesignTokens.phaseColor(for: phase))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(DesignTokens.phaseColor(for: phase).opacity(0.15))
                .clipShape(Capsule())
        }
    }

    private func scoreRow(extraction: TabScreenExtraction) -> some View {
        HStack(spacing: 10) {
            // Blue team score
            HStack(spacing: 4) {
                Circle()
                    .fill(DesignTokens.teamBlue)
                    .frame(width: 8, height: 8)
                Text("\(extraction.blueTeam.kills)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignTokens.teamBlue)
                    .monospacedDigit()
            }

            Text("vs")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            // Red team score
            HStack(spacing: 4) {
                Text("\(extraction.redTeam.kills)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignTokens.teamRed)
                    .monospacedDigit()
                Circle()
                    .fill(DesignTokens.teamRed)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var analysisCountBadge: some View {
        let count = isReview ? (session?.analyses.count ?? 0) : gameViewModel.analyses.count
        return Group {
            if count > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "camera.fill")
                        .font(.caption2)
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(DesignTokens.gold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(DesignTokens.gold.opacity(0.15))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        Picker("Tab", selection: $selectedTab) {
            ForEach(GameTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DesignTokens.bgSecondary)
    }

    // MARK: - Scoreboard Content

    @ViewBuilder
    private var scoreboardContent: some View {
        if let extraction = currentExtraction {
            ScoreboardView(
                extraction: extraction,
                highlightPlayerName: resolvedPlayerName
            )
        } else {
            VStack(spacing: 12) {
                Image(systemName: "tablecells")
                    .font(.system(size: 40))
                    .foregroundStyle(DesignTokens.muted)
                Text("Aucune donnee de scoreboard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Ajoutez un screenshot pour voir le scoreboard.")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.muted)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding(.vertical, 40)
        }
    }

    // MARK: - Review Content

    @ViewBuilder
    private var reviewContent: some View {
        if let session {
            ForEach(session.analyses) { analysis in
                AnalysisCardView(analysis: analysis)
                    .id(analysis.id)
            }
        }
    }

    // MARK: - Live Content

    @ViewBuilder
    private var liveContent: some View {
        // Completed analyses
        ForEach(gameViewModel.analyses) { analysis in
            AnalysisCardView(analysis: analysis)
                .id(analysis.id)
        }

        // Currently streaming
        if gameViewModel.isLoading || gameViewModel.isStreaming {
            liveAnalysisCard
                .id("live-card")
        }

        // Error
        if let error = gameViewModel.error {
            errorCard(message: error)
        }
    }

    // MARK: - Live Analysis Card

    private var liveAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status
            HStack(spacing: 8) {
                PulsingDot()
                Text(gameViewModel.statusMessage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(DesignTokens.gold)
            }
            .padding(.bottom, 4)

            if gameViewModel.isStreaming && !gameViewModel.coachingText.isEmpty {
                Text(gameViewModel.coachingText)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(4)
                    .textSelection(.enabled)

                if gameViewModel.isStreaming {
                    HStack(spacing: 0) {
                        Spacer()
                        BlinkingCursor()
                    }
                }
            } else if gameViewModel.isLoading && !gameViewModel.isStreaming {
                loadingSkeleton
            }
        }
        .padding(16)
        .background(DesignTokens.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(DesignTokens.blue.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Loading Skeleton

    private var loadingSkeleton: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.bgCardHover)
                    .frame(height: 14)
                    .frame(maxWidth: index == 3 ? 180 : .infinity)
                    .modifier(ShimmerEffect())
            }
        }
    }

    // MARK: - Error Card

    private func errorCard(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DesignTokens.teamRed)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            Button("Reessayer") {
                gameViewModel.error = nil
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(DesignTokens.blue)
        }
        .padding(14)
        .background(DesignTokens.teamRed.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Floating Screenshot Button (FAB)

    private var floatingScreenshotButton: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .screenshots
        ) {
            HStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.body)
                    .fontWeight(.medium)
                Text("Nouveau Screenshot")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(DesignTokens.blueGradient)
            .clipShape(Capsule())
            .shadow(color: DesignTokens.blue.opacity(0.4), radius: 12, y: 4)
        }
        .disabled(gameViewModel.isLoading)
    }

    // MARK: - Helpers

    private var currentExtraction: TabScreenExtraction? {
        // In review mode, gameViewModel is empty — use the session's data instead.
        if isReview {
            return session?.latestAnalysis?.extraction
        }
        return gameViewModel.currentExtraction ?? gameViewModel.analyses.last?.extraction
    }

    private var currentPhase: GamePhase {
        if isReview {
            return session?.latestAnalysis?.gamePhase ?? .early
        }
        return gameViewModel.gamePhase ?? gameViewModel.analyses.last?.gamePhase ?? .early
    }

    private var currentPhaseDisplay: String {
        currentPhase.displayName
    }

    /// Resolves champion name from live playerInfo or review session.
    private var resolvedChampionName: String? {
        if isReview {
            return session?.playerChampion
        }
        return gameViewModel.playerInfo?.champion
    }

    /// Resolves role from live playerInfo or review session.
    private var resolvedRole: Role? {
        if isReview {
            return session?.playerRole
        }
        return gameViewModel.playerInfo?.role
    }

    /// Resolves team from live playerInfo or review session.
    private var resolvedTeam: Team? {
        if isReview {
            return session?.playerTeam
        }
        return gameViewModel.playerInfo?.team
    }

    /// Resolves the player summoner name for scoreboard highlighting.
    private var resolvedPlayerName: String? {
        if isReview {
            return session?.riotId
        }
        return gameViewModel.playerInfo?.name
    }

    private func phaseColor(for raw: String) -> Color {
        switch raw {
        case "early": DesignTokens.phaseEarly
        case "mid": DesignTokens.phaseMid
        case "late": DesignTokens.phaseLate
        default: DesignTokens.muted
        }
    }

    private func teamGradient(for raw: String) -> LinearGradient {
        let colors: [Color] = raw == "blue"
            ? [DesignTokens.teamBlueBg, Color(hex: 0x0D3F73)]
            : [DesignTokens.teamRedBg, Color(hex: 0x742020)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func handleNewScreenshot(item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            // Reset so the user can retry the same image
            selectedItem = nil
            return
        }

        gameViewModel.analyzeScreenshot(image: image)
        // Reset so the user can re-select the same image later
        selectedItem = nil
    }
}

// MARK: - Blinking Cursor

struct BlinkingCursor: View {
    @State private var isVisible = true

    var body: some View {
        Rectangle()
            .fill(DesignTokens.blue)
            .frame(width: 2, height: 16)
            .opacity(isVisible ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible.toggle()
                }
            }
    }
}

// MARK: - Pulsing Dot

struct PulsingDot: View {
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(DesignTokens.blue)
            .frame(width: 8, height: 8)
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.6 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.4 : 0.8)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    NavigationStack {
        GameView()
            .environment(AppState())
    }
}
