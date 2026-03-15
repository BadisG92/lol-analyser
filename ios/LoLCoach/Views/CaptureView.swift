import SwiftUI
import PhotosUI

// MARK: - CaptureView

/// Screen where the player imports a TAB screenshot from their photo library.
///
/// Redesigned as a clear 3-step funnel: Import -> Preview -> Analyze.
/// Uses gaming-style step indicators, a prominent drop zone with pulsing
/// animation, a progress-bar quality indicator, and GlowButton for the CTA.
struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var imageQuality: ImageQuality?
    @State private var isProcessing = false
    @State private var navigateToGame = false
    @State private var gameViewModel = GameViewModel()

    /// Pulse animation toggle for the empty drop zone.
    @State private var isPulsing = false

    /// Animated progress value for the analyze button spinner.
    @State private var spinnerRotation: Double = 0

    /// Whether the quality is too low to proceed.
    private var isQualityTooLow: Bool {
        imageQuality == .poor
    }

    /// Current step in the funnel (1-based).
    private var currentStep: Int {
        if selectedImage == nil { return 1 }
        if isProcessing || !navigateToGame { return selectedImage != nil ? 2 : 1 }
        return 3
    }

    var body: some View {
        ZStack {
            DesignTokens.bgGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    instructionsCard
                    imagePickerSection

                    if let quality = imageQuality {
                        qualityIndicator(quality: quality)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    if selectedImage != nil && !isQualityTooLow {
                        analyzeButton
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    if let error = gameViewModel.error {
                        errorBanner(message: error)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
                .animation(.easeInOut(duration: 0.35), value: selectedImage != nil)
                .animation(.easeInOut(duration: 0.35), value: imageQuality)
            }
        }
        .navigationTitle("Capture")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToGame) {
            GameView(gameViewModel: gameViewModel)
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                await loadImage(from: newValue)
            }
        }
        .onChange(of: navigateToGame) { _, isNavigating in
            // Reset isProcessing when the user returns from GameView
            // (navigateToGame flips back to false when the view is dismissed)
            if !isNavigating {
                isProcessing = false
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Instructions Card

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "gamecontroller.fill")
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.gold)
                Text("Comment faire")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
            }

            // Step indicators with connecting lines
            HStack(spacing: 0) {
                stepIndicator(
                    step: 1,
                    icon: "keyboard",
                    label: "TAB en jeu",
                    isActive: currentStep >= 1
                )

                connectingLine(isActive: currentStep >= 2)

                stepIndicator(
                    step: 2,
                    icon: "camera.viewfinder",
                    label: "Screenshot",
                    isActive: currentStep >= 2
                )

                connectingLine(isActive: currentStep >= 3)

                stepIndicator(
                    step: 3,
                    icon: "arrow.up.doc",
                    label: "Importer ici",
                    isActive: currentStep >= 3
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(DesignTokens.bgCard.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    DesignTokens.gold.opacity(0.3),
                                    DesignTokens.gold.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private func stepIndicator(step: Int, icon: String, label: String, isActive: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        isActive
                            ? DesignTokens.blue.opacity(0.2)
                            : DesignTokens.bgCardHover.opacity(0.5)
                    )
                    .frame(width: 44, height: 44)

                Circle()
                    .strokeBorder(
                        isActive ? DesignTokens.blue : DesignTokens.muted.opacity(0.4),
                        lineWidth: 1.5
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isActive ? DesignTokens.blue : DesignTokens.muted)
            }

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isActive ? .white.opacity(0.9) : DesignTokens.muted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 70)
        }
        .frame(maxWidth: .infinity)
    }

    private func connectingLine(isActive: Bool) -> some View {
        VStack {
            Rectangle()
                .fill(
                    isActive
                        ? DesignTokens.blue.opacity(0.6)
                        : DesignTokens.muted.opacity(0.25)
                )
                .frame(height: 2)
                .frame(maxWidth: 40)
                .offset(y: -10) // Align with step circles
            Spacer()
                .frame(height: 18)
        }
    }

    // MARK: - PhotosPicker / Drop Zone

    private var imagePickerSection: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .screenshots
        ) {
            if let image = selectedImage {
                // Image selected state: prominent preview
                imagePreviewContent(image: image)
            } else {
                // Empty state: large dashed drop zone with pulsing animation
                emptyDropZone
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyDropZone: some View {
        VStack(spacing: 14) {
            ZStack {
                // Pulsing background circle
                Circle()
                    .fill(DesignTokens.blue.opacity(isPulsing ? 0.15 : 0.05))
                    .frame(width: 80, height: 80)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)

                Image(systemName: "photo.badge.plus.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(DesignTokens.blue)
                    .symbolRenderingMode(.hierarchical)
            }

            Text("Importer un screenshot")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Selectionnez la capture d'ecran TAB de votre game")
                .font(.caption)
                .foregroundStyle(DesignTokens.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 52)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.blue.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    DesignTokens.blue.opacity(isPulsing ? 0.5 : 0.25),
                    style: StrokeStyle(lineWidth: 2, dash: [10, 6])
                )
        )
    }

    // MARK: - Image Preview (inside picker zone)

    private func imagePreviewContent(image: UIImage) -> some View {
        VStack(spacing: 14) {
            // Preview image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(DesignTokens.bgCardHover, lineWidth: 1)
                )
                .shadow(color: DesignTokens.blue.opacity(0.2), radius: 16, y: 6)
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)

            // Metadata row
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left.and.right")
                        .font(.caption2)
                    Text("\(Int(image.size.width * image.scale))px")
                        .font(.caption)
                        .monospacedDigit()
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.and.down")
                        .font(.caption2)
                    Text("\(Int(image.size.height * image.scale))px")
                        .font(.caption)
                        .monospacedDigit()
                }
            }
            .foregroundStyle(DesignTokens.muted)

            // Change button
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                Text("Changer de screenshot")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(DesignTokens.blue)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(DesignTokens.blue.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .strokeBorder(DesignTokens.blue.opacity(0.25), lineWidth: 1)
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.bgCard.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(DesignTokens.bgCardHover, lineWidth: 1)
        )
    }

    // MARK: - Quality Indicator (Progress Bar Style)

    private func qualityIndicator(quality: ImageQuality) -> some View {
        let color: Color = switch quality {
        case .good: DesignTokens.phaseEarly
        case .acceptable: DesignTokens.phaseMid
        case .poor: DesignTokens.phaseLate
        }

        let icon: String = switch quality {
        case .good: "checkmark.circle.fill"
        case .acceptable: "exclamationmark.triangle.fill"
        case .poor: "xmark.circle.fill"
        }

        let fillFraction: CGFloat = switch quality {
        case .good: 1.0
        case .acceptable: 0.6
        case .poor: 0.25
        }

        let qualityLabel: String = switch quality {
        case .good: "Bonne"
        case .acceptable: "Acceptable"
        case .poor: "Insuffisante"
        }

        return VStack(alignment: .leading, spacing: 10) {
            // Header row: icon + label + quality badge
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)

                Text("Qualite de l'image")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Spacer()

                Text(qualityLabel)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.15))
                    )
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.bgCardHover)
                        .frame(height: 8)

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * fillFraction, height: 8)
                        .animation(.easeOut(duration: 0.6), value: fillFraction)
                }
            }
            .frame(height: 8)

            // Description text
            Text(quality.displayMessage)
                .font(.caption)
                .foregroundStyle(DesignTokens.muted)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(color.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Analyze Button

    private var analyzeButton: some View {
        Group {
            if isProcessing {
                // Animated processing state
                HStack(spacing: 12) {
                    // Rotating sparkle icon
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(spinnerRotation))
                        .onAppear {
                            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                                spinnerRotation = 360
                            }
                        }
                        .onDisappear {
                            spinnerRotation = 0
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Analyse en cours...")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)

                        // Indeterminate animated bar
                        ProgressView()
                            .progressViewStyle(.linear)
                            .tint(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    LinearGradient(
                        colors: [
                            DesignTokens.blueDeep.opacity(0.7),
                            DesignTokens.blue.opacity(0.7)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
            } else {
                GlowButton(
                    title: "Analyser",
                    icon: "sparkles",
                    gradient: [DesignTokens.blueDeep, DesignTokens.blue]
                ) {
                    startAnalysis()
                }
            }
        }
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.octagon.fill")
                .foregroundStyle(DesignTokens.phaseLate)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(3)

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.phaseLate.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(DesignTokens.phaseLate.opacity(0.25), lineWidth: 1)
                )
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            selectedImage = nil
            imageQuality = .poor
            return
        }

        selectedImage = uiImage
        imageQuality = ImageProcessor.estimateQuality(image: uiImage)
    }

    private func startAnalysis() {
        guard let image = selectedImage else { return }
        isProcessing = true

        gameViewModel.startNewGame(
            image: image,
            riotId: appState.riotId,
            region: appState.region
        )

        // Only navigate if startNewGame did not set an immediate error
        // (e.g. image compression failure)
        guard gameViewModel.error == nil else {
            isProcessing = false
            return
        }
        navigateToGame = true
    }
}

#Preview {
    NavigationStack {
        CaptureView()
            .environment(AppState())
    }
}
