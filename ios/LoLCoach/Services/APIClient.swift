import Foundation

// MARK: - API Errors

enum APIClientError: LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(String)
    case networkError(Error)
    case imageDataMissing

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse:
            return "Invalid response from server."
        case .httpError(let code, let message):
            return "HTTP \(code): \(message ?? "Unknown error")"
        case .decodingError(let detail):
            return "Decoding error: \(detail)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .imageDataMissing:
            return "Image data is missing or empty."
        }
    }
}

// MARK: - API Environment

/// Backend environment configuration.
enum APIEnvironment {
    case development
    case production

    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:8787"
        case .production:
            return "https://api.lolcoach.app"
        }
    }
}

// MARK: - Game Session API Response DTO

/// A Codable representation of the `GameSession` as returned by `GET /game/:id`.
///
/// This is a Data Transfer Object that mirrors the backend's JSON shape.
/// The ViewModel layer is responsible for converting this into the SwiftData
/// `GameSession` model if needed.
struct GameSessionResponse: Codable {
    let id: String
    let riotId: String
    let region: String
    let playerTeam: String
    let playerRole: String
    let playerChampion: String
    let playersBlue: [PlayerEnrichedResponse]
    let playersRed: [PlayerEnrichedResponse]
    let analyses: [ScreenshotAnalysis]
    let createdAt: Double

    enum CodingKeys: String, CodingKey {
        case id
        case riotId = "riot_id"
        case region
        case playerTeam = "player_team"
        case playerRole = "player_role"
        case playerChampion = "player_champion"
        case playersBlue = "players_blue"
        case playersRed = "players_red"
        case analyses
        case createdAt = "created_at"
    }
}

/// Enriched player data from the backend (includes OP.GG stats).
struct PlayerEnrichedResponse: Codable {
    let name: String
    let champion: String
    let level: Int
    let kills: Int
    let deaths: Int
    let assists: Int
    let cs: Int
    let items: [String]
    let summonerSpells: [String]
    let estimatedRole: String
    let rank: String
    let winRate: Double
    let gamesPlayed: Int
    let recentPerformance: String
    let isAutofill: Bool
    let championMastery: String

    enum CodingKeys: String, CodingKey {
        case name, champion, level, kills, deaths, assists, cs, items
        case summonerSpells = "summoner_spells"
        case estimatedRole = "estimated_role"
        case rank
        case winRate = "win_rate"
        case gamesPlayed = "games_played"
        case recentPerformance = "recent_performance"
        case isAutofill = "is_autofill"
        case championMastery = "champion_mastery"
    }
}

// MARK: - API Client

/// Singleton service for communicating with the LoL Coach backend.
///
/// All network calls use native `URLSession` with structured concurrency.
/// SSE streaming endpoints return `AsyncThrowingStream<SSEEvent, Error>`,
/// where `SSEEvent` is the enum defined in `Models/SSEEvent.swift`.
///
/// ```swift
/// // Initialize a game:
/// let stream = APIClient.shared.initGame(image: jpegData, riotId: "Player#EUW", region: "euw1")
/// for try await event in stream {
///     switch event {
///     case .status(let s): print(s.message)
///     case .coaching(let c): print(c.text)
///     case .done(let d): print("Game \(d.gameId) started")
///     default: break
///     }
/// }
/// ```
final class APIClient: Sendable {

    // MARK: - Singleton

    static let shared = APIClient()

    // MARK: - Configuration

    /// The current backend environment. Set once at app launch before any requests.
    nonisolated(unsafe) static var environment: APIEnvironment = .development

    private var baseURL: String { APIClient.environment.baseURL }

    // MARK: - URLSession

    /// Standard session for short JSON requests.
    private let session: URLSession

    /// Streaming session with long timeouts for SSE connections.
    private let streamingSession: URLSession

    // MARK: - Init

    private init() {
        let standardConfig = URLSessionConfiguration.default
        standardConfig.timeoutIntervalForRequest = 30
        standardConfig.timeoutIntervalForResource = 60
        standardConfig.httpAdditionalHeaders = [
            "Accept": "application/json",
        ]
        self.session = URLSession(configuration: standardConfig)

        let streamingConfig = URLSessionConfiguration.default
        streamingConfig.timeoutIntervalForRequest = 300  // 5 min for long SSE streams
        streamingConfig.timeoutIntervalForResource = 600 // 10 min total
        streamingConfig.httpAdditionalHeaders = [
            "Accept": "text/event-stream",
        ]
        self.streamingSession = URLSession(configuration: streamingConfig)
    }

    // MARK: - Public API: SSE Streaming

    /// Initialize a new game session by uploading the first screenshot.
    ///
    /// Sends `multipart/form-data` to `POST /game/init` and returns an SSE
    /// stream of events: `status`, `extraction`, `player`, `players_data`,
    /// `coaching` (multiple chunks), `done`.
    ///
    /// - Parameters:
    ///   - image: JPEG data (use `ImageProcessor.compressForUpload` first).
    ///   - riotId: The player's Riot ID (e.g. "PlayerName#EUW").
    ///   - region: The server region code (e.g. "euw1").
    /// - Returns: A stream of `SSEEvent` values.
    func initGame(
        image: Data,
        riotId: String,
        region: String
    ) -> AsyncThrowingStream<SSEEvent, Error> {
        guard !image.isEmpty else {
            return AsyncThrowingStream { $0.finish(throwing: APIClientError.imageDataMissing) }
        }

        let urlString = "\(baseURL)/game/init"
        guard let url = URL(string: urlString) else {
            return AsyncThrowingStream { $0.finish(throwing: APIClientError.invalidURL(urlString)) }
        }

        let boundary = Self.generateBoundary()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = Self.buildMultipartBody(
            boundary: boundary,
            imageData: image,
            fields: [
                "riot_id": riotId,
                "region": region,
            ]
        )

        return makeSSEStream(request: request)
    }

    /// Analyze a subsequent screenshot within an existing game session.
    ///
    /// Sends `multipart/form-data` to `POST /game/:id/analyze` and returns an
    /// SSE stream of events: `status`, `extraction`, `coaching`, `done`.
    ///
    /// - Parameters:
    ///   - gameId: The UUID of the current game session.
    ///   - image: JPEG data (use `ImageProcessor.compressForUpload` first).
    /// - Returns: A stream of `SSEEvent` values.
    func analyzeScreenshot(
        gameId: String,
        image: Data
    ) -> AsyncThrowingStream<SSEEvent, Error> {
        guard !image.isEmpty else {
            return AsyncThrowingStream { $0.finish(throwing: APIClientError.imageDataMissing) }
        }

        let urlString = "\(baseURL)/game/\(gameId)/analyze"
        guard let url = URL(string: urlString) else {
            return AsyncThrowingStream { $0.finish(throwing: APIClientError.invalidURL(urlString)) }
        }

        let boundary = Self.generateBoundary()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = Self.buildMultipartBody(
            boundary: boundary,
            imageData: image,
            fields: [:]
        )

        return makeSSEStream(request: request)
    }

    // MARK: - Public API: REST

    /// Retrieve a complete game session by its ID.
    ///
    /// - Parameter id: The game session UUID.
    /// - Returns: A decoded `GameSessionResponse` DTO.
    func getGameSession(id: String) async throws -> GameSessionResponse {
        let urlString = "\(baseURL)/game/\(id)"
        guard let url = URL(string: urlString) else {
            throw APIClientError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw APIClientError.httpError(statusCode: httpResponse.statusCode, message: body)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(GameSessionResponse.self, from: data)
        } catch {
            throw APIClientError.decodingError(error.localizedDescription)
        }
    }

    /// Check if the backend is healthy and reachable.
    ///
    /// - Returns: `true` if the backend responds with `{"status":"ok"}`.
    func healthCheck() async throws -> Bool {
        let urlString = "\(baseURL)/health"
        guard let url = URL(string: urlString) else {
            throw APIClientError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                return false
            }

            struct HealthResponse: Decodable {
                let status: String
            }

            guard let health = try? JSONDecoder().decode(HealthResponse.self, from: data) else {
                return false
            }

            return health.status == "ok"
        } catch {
            return false
        }
    }

    // MARK: - SSE Stream Builder

    /// Creates an `AsyncThrowingStream<SSEEvent, Error>` from a URLRequest by
    /// opening a streaming connection and delegating to `SSEClient`.
    private func makeSSEStream(request: URLRequest) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await streamingSession.bytes(for: request)

                    // Check HTTP status before starting the SSE parser.
                    if let httpResponse = response as? HTTPURLResponse,
                       !(200...299).contains(httpResponse.statusCode) {
                        continuation.finish(
                            throwing: APIClientError.httpError(
                                statusCode: httpResponse.statusCode,
                                message: "Server returned \(httpResponse.statusCode)"
                            )
                        )
                        return
                    }

                    // Delegate to SSEClient for line-by-line parsing.
                    let events = SSEClient.events(from: bytes, response: response)
                    for try await event in events {
                        if Task.isCancelled { break }
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Multipart Form Data

    /// Build a `multipart/form-data` body containing one JPEG image and optional text fields.
    ///
    /// The image is sent with:
    /// - Field name: `image`
    /// - Filename: `screenshot.jpg`
    /// - Content-Type: `image/jpeg`
    private static func buildMultipartBody(
        boundary: String,
        imageData: Data,
        fields: [String: String]
    ) -> Data {
        var body = Data()
        let crlf = "\r\n"

        // Append text fields first (order matches server expectation).
        for (key, value) in fields.sorted(by: { $0.key < $1.key }) {
            body.appendString("--\(boundary)\(crlf)")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\(crlf)")
            body.appendString(crlf)
            body.appendString("\(value)\(crlf)")
        }

        // Append the image file part.
        body.appendString("--\(boundary)\(crlf)")
        body.appendString("Content-Disposition: form-data; name=\"image\"; filename=\"screenshot.jpg\"\(crlf)")
        body.appendString("Content-Type: image/jpeg\(crlf)")
        body.appendString(crlf)
        body.append(imageData)
        body.appendString(crlf)

        // Closing boundary.
        body.appendString("--\(boundary)--\(crlf)")

        return body
    }

    /// Generate a unique multipart boundary string.
    private static func generateBoundary() -> String {
        "LoLCoach-\(UUID().uuidString)"
    }
}

// MARK: - Data + String Helper

private extension Data {
    /// Append a UTF-8 encoded string to this Data buffer.
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
