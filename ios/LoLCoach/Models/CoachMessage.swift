import Foundation
import Observation

enum MessageType: String {
    case system
    case coaching
    case userAction
}

@Observable
@MainActor
final class CoachMessage: Identifiable {
    let id: UUID
    let type: MessageType
    let timestamp: Date
    private(set) var text: String
    private(set) var isStreaming: Bool

    init(type: MessageType, text: String = "", isStreaming: Bool = false) {
        self.id = UUID()
        self.type = type
        self.timestamp = .now
        self.text = text
        self.isStreaming = isStreaming
    }

    func append(_ chunk: String) {
        text += chunk
    }

    func finishStreaming() {
        isStreaming = false
    }

    static func system(_ text: String) -> CoachMessage {
        CoachMessage(type: .system, text: text)
    }

    static func streaming() -> CoachMessage {
        CoachMessage(type: .coaching, isStreaming: true)
    }

    static func userAction(_ text: String) -> CoachMessage {
        CoachMessage(type: .userAction, text: text)
    }
}
