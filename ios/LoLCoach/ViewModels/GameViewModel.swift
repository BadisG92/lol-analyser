import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class GameViewModel {
    var isLoading = false
    var statusMessage = ""
    var coachingText = ""
    var currentExtraction: TabScreenExtraction?
    var playerInfo: SSEPlayerInfo?
    var gameId: String?
    var gamePhase: GamePhase?
    var error: String?
    var analyses: [ScreenshotAnalysis] = []
    var isStreaming = false

    private var streamingTask: Task<Void, Never>?

    // MARK: - Public API

    func startNewGame(image: UIImage, riotId: String, region: Region) {
        resetState()

        guard let imageData = try? ImageProcessor.compressForUpload(image: image) else {
            error = "Impossible de compresser l'image."
            return
        }

        isLoading = true
        statusMessage = "Envoi du screenshot..."

        streamingTask?.cancel()
        streamingTask = Task {
            let stream = APIClient.shared.initGame(
                image: imageData,
                riotId: riotId,
                region: region.rawValue
            )

            await processSSEStream(stream)
        }
    }

    func analyzeScreenshot(image: UIImage) {
        guard let gid = gameId else {
            error = "Pas de session de game active."
            return
        }

        guard let imageData = try? ImageProcessor.compressForUpload(image: image) else {
            error = "Impossible de compresser l'image."
            return
        }

        isLoading = true
        isStreaming = false
        coachingText = ""
        error = nil
        statusMessage = "Envoi du screenshot..."

        streamingTask?.cancel()
        streamingTask = Task {
            let stream = APIClient.shared.analyzeScreenshot(
                gameId: gid,
                image: imageData
            )

            await processSSEStream(stream)
        }
    }

    func cancel() {
        streamingTask?.cancel()
        isLoading = false
        isStreaming = false
    }

    // MARK: - SSE Stream Processing

    private func processSSEStream(_ stream: AsyncThrowingStream<SSEEvent, Error>) async {
        do {
            for try await event in stream {
                guard !Task.isCancelled else { return }

                switch event {
                case .status(let status):
                    statusMessage = status.message

                case .extraction(let extraction):
                    currentExtraction = extraction
                    statusMessage = "Données extraites, récupération des joueurs..."

                case .player(let info):
                    playerInfo = info
                    statusMessage = "Joueur identifié: \(info.champion)..."

                case .playersData(let data):
                    statusMessage = data.message

                case .coaching(let chunk):
                    if !isStreaming {
                        isStreaming = true
                        statusMessage = "Le coach analyse..."
                    }
                    coachingText += chunk.text

                case .done(let done):
                    gameId = done.gameId
                    gamePhase = done.phase

                    // Build the analysis from accumulated data
                    if let extraction = currentExtraction {
                        let analysis = ScreenshotAnalysis(
                            id: UUID().uuidString,
                            timestamp: Date().timeIntervalSince1970,
                            extraction: extraction,
                            coaching: coachingText,
                            gamePhase: done.phase
                        )
                        analyses.append(analysis)
                    }

                    isLoading = false
                    isStreaming = false
                    statusMessage = ""
                    coachingText = ""

                case .error(let err):
                    error = err.message
                    isLoading = false
                    isStreaming = false
                }
            }
        } catch {
            if !Task.isCancelled {
                self.error = "Erreur: \(error.localizedDescription)"
                self.isLoading = false
                self.isStreaming = false
            }
        }
    }

    // MARK: - Private

    private func resetState() {
        analyses = []
        coachingText = ""
        currentExtraction = nil
        playerInfo = nil
        gameId = nil
        gamePhase = nil
        error = nil
        statusMessage = ""
    }
}
