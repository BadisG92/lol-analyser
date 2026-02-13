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
            Color(hex: 0x0A0E1A)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                gameInfoHeader

                Divider()
                    .overlay(Color(hex: 0x1E293B))

                // Chat thread
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if isReview {
                                reviewContent
                            } else {
                                liveContent
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: gameViewModel.coachingText) { _, _ in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("live-card", anchor: .bottom)
                        }
                    }
                    .onChange(of: gameViewModel.analyses.count) { _, _ in
                        if let lastId = gameViewModel.analyses.last?.id {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastId, anchor: .top)
                            }
                        }
                    }
                }

                if !isReview {
                    bottomBar
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
                        .tint(Color(hex: 0xC89B3C))
                }
            }
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                await handleNewScreenshot(item: newValue)
            }
        }
        .preferredColorScheme(.dark)
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

    // MARK: - Game Info Header

    private var gameInfoHeader: some View {
        HStack(spacing: 16) {
            if let extraction = currentExtraction {
                // Time
                VStack(spacing: 2) {
                    Text("\(Int(extraction.gameTimeMinutes)) min")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Temps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 30)
                    .overlay(Color(hex: 0x1E293B))

                // Score
                VStack(spacing: 2) {
                    HStack(spacing: 8) {
                        Text("\(extraction.blueTeam.kills)")
                            .foregroundStyle(Color(hex: 0x4A9EEF))
                        Text("-")
                            .foregroundStyle(.secondary)
                        Text("\(extraction.redTeam.kills)")
                            .foregroundStyle(Color(hex: 0xEF4444))
                    }
                    .font(.title3)
                    .fontWeight(.bold)

                    Text("Score")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 30)
                    .overlay(Color(hex: 0x1E293B))

                // Phase
                VStack(spacing: 2) {
                    Text(currentPhaseDisplay)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: 0xC89B3C))
                    Text("Phase")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 4) {
                    if isReview, let session {
                        Text(session.playerChampion)
                            .font(.headline)
                            .foregroundStyle(.white)
                    } else {
                        Text("En attente d'analyse...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Analysis count
            let count = isReview ? (session?.analyses.count ?? 0) : gameViewModel.analyses.count
            if count > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "camera.fill")
                        .font(.caption2)
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color(hex: 0xC89B3C))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: 0xC89B3C).opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: 0x111827))
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
                    .foregroundStyle(Color(hex: 0xC89B3C))
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
        .background(Color(hex: 0x1A1F2E))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(hex: 0x0D7FD9).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Loading Skeleton

    private var loadingSkeleton: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: 0x1E293B))
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
                .foregroundStyle(Color(hex: 0xEF4444))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            Button("Reessayer") {
                gameViewModel.error = nil
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color(hex: 0x0D7FD9))
        }
        .padding(14)
        .background(Color(hex: 0xEF4444).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color(hex: 0x1E293B))

            PhotosPicker(
                selection: $selectedItem,
                matching: .screenshots
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.body)
                    Text("Nouveau Screenshot")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0x0A5CA8), Color(hex: 0x0D7FD9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(gameViewModel.isLoading)
            .opacity(gameViewModel.isLoading ? 0.5 : 1.0)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: 0x111827))
        }
    }

    // MARK: - Helpers

    private var currentExtraction: TabScreenExtraction? {
        gameViewModel.currentExtraction ?? gameViewModel.analyses.last?.extraction
    }

    private var currentPhaseDisplay: String {
        let phase = gameViewModel.analyses.last?.gamePhase ?? .early
        return phase.displayName
    }

    private func phaseColor(for raw: String) -> Color {
        switch raw {
        case "early": Color(hex: 0x22C55E)
        case "mid": Color(hex: 0xF59E0B)
        case "late": Color(hex: 0xEF4444)
        default: Color(hex: 0x3B4A6B)
        }
    }

    private func teamGradient(for raw: String) -> LinearGradient {
        let colors: [Color] = raw == "blue"
            ? [Color(hex: 0x0A5CA8), Color(hex: 0x0D3F73)]
            : [Color(hex: 0x9B2C2C), Color(hex: 0x742020)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func handleNewScreenshot(item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }

        gameViewModel.analyzeScreenshot(image: image)
    }
}

// MARK: - Blinking Cursor

struct BlinkingCursor: View {
    @State private var isVisible = true

    var body: some View {
        Rectangle()
            .fill(Color(hex: 0x0D7FD9))
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
            .fill(Color(hex: 0x0D7FD9))
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
