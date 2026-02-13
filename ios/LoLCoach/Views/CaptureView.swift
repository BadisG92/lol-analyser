import SwiftUI
import PhotosUI

// MARK: - CaptureView

/// Screen where the player imports a TAB screenshot from their photo library.
///
/// Shows a PhotosPicker, a preview of the selected image, a quality indicator
/// (using `ImageProcessor.estimateQuality`), and an "Analyser" button that
/// compresses the image and navigates to `GameView`.
struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var imageQuality: ImageQuality?
    @State private var isProcessing = false
    @State private var navigateToGame = false
    @State private var gameViewModel = GameViewModel()

    /// Whether the quality is too low to proceed.
    private var isQualityTooLow: Bool {
        imageQuality == .poor
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0A0E1A), Color(hex: 0x111827)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    instructionsCard
                    imagePickerSection

                    if let image = selectedImage {
                        imagePreviewSection(image: image)
                    }

                    if let quality = imageQuality {
                        qualityIndicator(quality: quality)
                    }

                    if selectedImage != nil && !isQualityTooLow {
                        analyzeButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
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
        .preferredColorScheme(.dark)
    }

    // MARK: - Instructions

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Color(hex: 0xC89B3C))
                Text("Comment faire")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                instructionRow(number: "1", text: "Appuyez sur TAB en jeu")
                instructionRow(number: "2", text: "Prenez un screenshot (capture d'ecran)")
                instructionRow(number: "3", text: "Importez-le ici pour l'analyse")
            }
        }
        .padding(16)
        .background(Color(hex: 0x1A1F2E).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color(hex: 0x0D7FD9))
                .frame(width: 22, height: 22)
                .background(Color(hex: 0x0D7FD9).opacity(0.2))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - PhotosPicker

    private var imagePickerSection: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .screenshots
        ) {
            VStack(spacing: 16) {
                if selectedImage == nil {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: 0x0D7FD9))

                    Text("Importer un screenshot")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Selectionnez la capture d'ecran TAB de votre game")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.subheadline)
                        Text("Changer de screenshot")
                            .font(.subheadline)
                    }
                    .foregroundStyle(Color(hex: 0x0D7FD9))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, selectedImage == nil ? 48 : 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        Color(hex: 0x0D7FD9).opacity(0.4),
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: selectedImage == nil ? [8, 4] : []
                        )
                    )
            )
            .background(Color(hex: 0x0D7FD9).opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview

    private func imagePreviewSection(image: UIImage) -> some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color(hex: 0x1E293B), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left.and.right")
                        .font(.caption2)
                    Text("\(Int(image.size.width))px")
                        .font(.caption)
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.and.down")
                        .font(.caption2)
                    Text("\(Int(image.size.height))px")
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Quality Indicator

    private func qualityIndicator(quality: ImageQuality) -> some View {
        let color: Color = switch quality {
        case .good: Color(hex: 0x22C55E)
        case .acceptable: Color(hex: 0xF59E0B)
        case .poor: Color(hex: 0xEF4444)
        }

        let icon: String = switch quality {
        case .good: "checkmark.circle.fill"
        case .acceptable: "exclamationmark.triangle.fill"
        case .poor: "xmark.circle.fill"
        }

        return HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)

            Text(quality.displayMessage)
                .font(.subheadline)
                .foregroundStyle(color)
                .lineLimit(2)

            Spacer()
        }
        .padding(14)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Analyze Button

    private var analyzeButton: some View {
        Button {
            startAnalysis()
        } label: {
            HStack(spacing: 10) {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                        .font(.title3)
                }
                Text("Analyser")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
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
        .disabled(isProcessing)
        .buttonStyle(.plain)
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

        isProcessing = false

        // Only navigate if startNewGame did not set an immediate error
        // (e.g. image compression failure)
        guard gameViewModel.error == nil else { return }
        navigateToGame = true
    }
}

#Preview {
    NavigationStack {
        CaptureView()
            .environment(AppState())
    }
}
