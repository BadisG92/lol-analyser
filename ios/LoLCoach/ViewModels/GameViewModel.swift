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

    /// Generation counter to discard events from stale (cancelled) streams.
    private var streamGeneration: Int = 0

    deinit {
        streamingTask?.cancel()
    }

    // MARK: - Public API

    func startNewGame(image: UIImage, riotId: String, region: Region) {
        resetState()
        isLoading = true
        statusMessage = "Compression de l'image..."

        streamingTask?.cancel()
        streamGeneration += 1
        let generation = streamGeneration
        streamingTask = Task {
            // Perform CPU-intensive image compression off the main actor.
            let imageData: Data
            do {
                imageData = try await Task.detached(priority: .userInitiated) {
                    try ImageProcessor.compressForUpload(image: image)
                }.value
            } catch {
                self.error = "Impossible de compresser l'image."
                self.isLoading = false
                return
            }

            guard !Task.isCancelled, generation == self.streamGeneration else { return }

            self.statusMessage = "Envoi du screenshot..."
            let stream = APIClient.shared.initGame(
                image: imageData,
                riotId: riotId,
                region: region.rawValue
            )

            await self.processSSEStream(stream, generation: generation)
        }
    }

    func analyzeScreenshot(image: UIImage) {
        guard let gid = gameId else {
            error = "Pas de session de game active."
            return
        }

        isLoading = true
        isStreaming = false
        coachingText = ""
        error = nil
        statusMessage = "Compression de l'image..."

        streamingTask?.cancel()
        streamGeneration += 1
        let generation = streamGeneration
        streamingTask = Task {
            // Perform CPU-intensive image compression off the main actor.
            let imageData: Data
            do {
                imageData = try await Task.detached(priority: .userInitiated) {
                    try ImageProcessor.compressForUpload(image: image)
                }.value
            } catch {
                self.error = "Impossible de compresser l'image."
                self.isLoading = false
                return
            }

            guard !Task.isCancelled, generation == self.streamGeneration else { return }

            self.statusMessage = "Envoi du screenshot..."
            let stream = APIClient.shared.analyzeScreenshot(
                gameId: gid,
                image: imageData
            )

            await self.processSSEStream(stream, generation: generation)
        }
    }

    func cancel() {
        streamingTask?.cancel()
        streamingTask = nil
        isLoading = false
        isStreaming = false
    }

    // MARK: - SSE Stream Processing

    private func processSSEStream(_ stream: AsyncThrowingStream<SSEEvent, Error>, generation: Int) async {
        do {
            for try await event in stream {
                guard !Task.isCancelled, generation == streamGeneration else { return }

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
                    // Only update gameId if the server provided one (init returns
                    // game_id; mid-game analyze does not). Setting it to nil here
                    // would break subsequent analyzeScreenshot() calls.
                    if let newGameId = done.gameId {
                        gameId = newGameId
                    }
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

            // The stream ended normally (loop exhausted). If isLoading is still
            // true, the server closed the connection without sending a "done" or
            // "error" event (e.g. network drop handled gracefully by URLSession).
            // Reset the loading state so the UI doesn't spin forever.
            if isLoading {
                isLoading = false
                isStreaming = false
                if error == nil {
                    error = "Connexion interrompue. Veuillez réessayer."
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
