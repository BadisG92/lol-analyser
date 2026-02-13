import Foundation

// MARK: - SSE Parsing Errors

enum SSEClientError: LocalizedError {
    case invalidHTTPResponse
    case httpError(statusCode: Int, body: String?)
    case decodingError(event: String, detail: String)
    case connectionLost
    case streamCancelled
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidHTTPResponse:
            return "Invalid HTTP response from server."
        case .httpError(let code, let body):
            return "HTTP \(code): \(body ?? "No details")"
        case .decodingError(let event, let detail):
            return "Failed to decode SSE event '\(event)': \(detail)"
        case .connectionLost:
            return "Connection to server lost."
        case .streamCancelled:
            return "SSE stream was cancelled."
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - SSE Client

/// Parses a raw `text/event-stream` response from `URLSession.bytes` into
/// a typed `AsyncThrowingStream<SSEEvent, Error>`.
///
/// The SSE wire format is:
/// ```
/// event: eventName\n
/// data: {"json":"data"}\n
/// \n
/// ```
///
/// This parser:
/// - Reads lines asynchronously via `URLSession.AsyncBytes.lines`
/// - Accumulates multi-line `data:` fields for the same event
/// - Emits a parsed `SSEEvent` on each blank-line delimiter
/// - Handles `retry:`, `id:`, and comment lines per the SSE spec
/// - Gracefully handles network errors and cancellation
///
/// Usage:
/// ```swift
/// let (bytes, response) = try await URLSession.shared.bytes(for: request)
/// let stream = SSEClient.events(from: bytes, response: response)
/// for try await event in stream { ... }
/// ```
enum SSEClient {

    /// Parse an SSE byte stream into typed `SSEEvent` values.
    ///
    /// - Parameters:
    ///   - bytes: The raw `URLSession.AsyncBytes` from a streaming request.
    ///   - response: The `URLResponse` to validate before parsing begins.
    /// - Returns: An `AsyncThrowingStream` that yields `SSEEvent` values.
    static func events(
        from bytes: URLSession.AsyncBytes,
        response: URLResponse
    ) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // Validate the HTTP response before we start reading lines.
                    try validateResponse(response)

                    var currentEvent: String?
                    var dataBuffer: [String] = []

                    for try await line in bytes.lines {
                        // Respect cooperative cancellation.
                        if Task.isCancelled {
                            continuation.finish(throwing: SSEClientError.streamCancelled)
                            return
                        }

                        // An empty line marks the end of an event block.
                        if line.isEmpty {
                            if let eventName = currentEvent, !dataBuffer.isEmpty {
                                let joinedData = dataBuffer.joined(separator: "\n")
                                if let event = SSEEvent.parse(event: eventName, data: joinedData) {
                                    // Check for terminal events before yielding.
                                    if case .error(let sseError) = event {
                                        continuation.yield(event)
                                        continuation.finish(
                                            throwing: SSEClientError.serverError(sseError.message)
                                        )
                                        return
                                    }

                                    continuation.yield(event)

                                    if case .done = event {
                                        continuation.finish()
                                        return
                                    }
                                }
                            }
                            // Reset for the next event block.
                            currentEvent = nil
                            dataBuffer.removeAll()
                            continue
                        }

                        // Parse individual SSE field lines.
                        if line.hasPrefix("event:") {
                            currentEvent = line
                                .dropFirst("event:".count)
                                .trimmingCharacters(in: .whitespaces)

                        } else if line.hasPrefix("data:") {
                            let value = String(line.dropFirst("data:".count))
                                .trimmingCharacters(in: .init(charactersIn: " "))
                            dataBuffer.append(value)

                        } else if line.hasPrefix("retry:") {
                            // The retry field specifies a reconnection interval in ms.
                            // Acknowledged but not acted upon — reconnection is handled
                            // at a higher level (APIClient or ViewModel).

                        } else if line.hasPrefix("id:") {
                            // Last-Event-ID for reconnection. Acknowledged but unused
                            // for this MVP implementation.

                        } else if line.hasPrefix(":") {
                            // SSE comment line — silently ignored.
                        }
                        // Lines that don't match any known field prefix are ignored
                        // per the SSE specification.
                    }

                    // The async-for loop ended: server closed the connection.
                    // Flush any remaining buffered event.
                    if let eventName = currentEvent, !dataBuffer.isEmpty {
                        let joinedData = dataBuffer.joined(separator: "\n")
                        if let event = SSEEvent.parse(event: eventName, data: joinedData) {
                            continuation.yield(event)
                        }
                    }

                    continuation.finish()

                } catch is CancellationError {
                    continuation.finish(throwing: SSEClientError.streamCancelled)
                } catch let urlError as URLError {
                    switch urlError.code {
                    case .cancelled:
                        continuation.finish(throwing: SSEClientError.streamCancelled)
                    case .networkConnectionLost, .notConnectedToInternet, .timedOut:
                        continuation.finish(throwing: SSEClientError.connectionLost)
                    default:
                        continuation.finish(throwing: urlError)
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Private Helpers

    /// Validate that the HTTP response is successful before parsing.
    private static func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SSEClientError.invalidHTTPResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw SSEClientError.httpError(
                statusCode: httpResponse.statusCode,
                body: nil
            )
        }
    }
}
