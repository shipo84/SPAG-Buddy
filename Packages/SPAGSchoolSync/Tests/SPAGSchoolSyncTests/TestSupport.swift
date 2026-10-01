import Foundation
@testable import SPAGSchoolSync

@MainActor
enum TestSupport {
    static func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("spag-tests-\(UUID().uuidString)", isDirectory: true)
    }

    /// A UserDefaults suite of its own, so tests never read or write the app's settings.
    static func defaults() -> UserDefaults {
        suite().defaults
    }

    static func suite() -> (defaults: UserDefaults, name: String) {
        let name = "spag-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return (defaults, name)
    }

    static func upload(answeredAt seconds: TimeInterval = 0, id: UUID = UUID()) -> AttemptUpload {
        AttemptUpload(
            clientAttemptId: id,
            questionId: "y4-fa-01",
            correct: true,
            answerGiven: "Before breakfast, Sam fed the cat.",
            timeTakenMs: 4000,
            hintUsed: false,
            sessionId: UUID(),
            sessionKind: "daily",
            assignmentId: nil,
            answeredAt: Date(timeIntervalSince1970: 1_790_000_000 + seconds)
        )
    }
}

/// Stands in for `POST /attempts`. By default it accepts everything it is sent.
@MainActor
final class FakeAttemptServer: AttemptUploading {
    private(set) var received: [[AttemptUpload]] = []
    private(set) var tokens: [String] = []
    var respond: ([AttemptUpload]) throws -> AttemptUploadResponse = {
        AttemptUploadResponse(accepted: $0.map(\.clientAttemptId), rejected: [])
    }

    var receivedIds: [UUID] { received.flatMap { $0.map(\.clientAttemptId) } }

    func uploadAttempts(_ attempts: [AttemptUpload], token: String) async throws -> AttemptUploadResponse {
        received.append(attempts)
        tokens.append(token)
        return try respond(attempts)
    }
}
