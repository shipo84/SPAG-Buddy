import Foundation
import SPAGCore

struct JoinRequest: Codable, Sendable {
    var classCode: String
    var avatarKey: String
    var pin: String
}

struct JoinResponse: Codable, Sendable {
    var pupilId: String
    var displayName: String
    var avatarKey: String
    var yearGroup: Int
    var className: String
    var classCode: String
    var deviceToken: String
}

struct AttemptUpload: Codable, Hashable, Sendable {
    var clientAttemptId: UUID
    var questionId: String
    var correct: Bool
    var answerGiven: String
    var timeTakenMs: Int
    var hintUsed: Bool
    var sessionId: UUID
    var sessionKind: String
    var assignmentId: String?
    var answeredAt: Date
}

struct AttemptBatch: Codable, Sendable {
    var attempts: [AttemptUpload]
}

struct AttemptUploadResponse: Codable, Sendable {
    struct Rejected: Codable, Sendable {
        var clientAttemptId: UUID
        var reason: String
    }

    var accepted: [UUID]
    var rejected: [Rejected]

    /// Attempts the device can stop sending: stored, or rejected for a reason that will not change on retry.
    var settledIds: Set<UUID> { Set(accepted).union(rejected.map(\.clientAttemptId)) }
}

struct AssignmentDTO: Codable, Hashable, Sendable {
    var id: String
    var title: String
    var objectiveCodes: [String]
    var spellingListId: String?
    /// `YYYY-MM-DD`
    var dueDate: String?

    var dueDateValue: Date? {
        guard let dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = .ukCalendar
        formatter.timeZone = Calendar.ukCalendar.timeZone
        formatter.locale = Locale(identifier: "en_GB_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dueDate)
    }
}

struct AssignmentsResponse: Codable, Sendable {
    var assignments: [AssignmentDTO]
}

struct RemoteContentManifest: Codable, Sendable {
    struct File: Codable, Sendable {
        var name: String
        var url: URL
    }

    var contentVersion: String
    var files: [File]
}

struct APIErrorBody: Codable, Sendable {
    var error: String
    var message: String?
}

enum APIError: Error, Equatable {
    case notConfigured
    /// Wrong login details, or the device is no longer linked (pupil deleted or class archived).
    case unauthorised
    case notFound
    case tooManyAttempts
    case badRequest(String)
    case server(Int)
    case transport

    static func from(status: Int, body: APIErrorBody?) -> APIError? {
        switch status {
        case 200..<300: nil
        case 400, 413: .badRequest(body?.message ?? "Bad request")
        case 401, 403: .unauthorised
        case 404: .notFound
        case 429: .tooManyAttempts
        default: .server(status)
        }
    }
}

enum SyncPlanner {
    static let batchSize = 100

    static func batches(_ uploads: [AttemptUpload], size: Int = batchSize) -> [[AttemptUpload]] {
        let ordered = uploads.sorted { $0.answeredAt < $1.answeredAt }
        return stride(from: 0, to: ordered.count, by: max(size, 1)).map {
            Array(ordered[$0..<min($0 + size, ordered.count)])
        }
    }

    /// Wait before retrying after `failures` consecutive failures: 10s, 20s, 40s ... capped at 15 minutes.
    static func retryDelay(afterFailures failures: Int) -> TimeInterval {
        guard failures > 0 else { return 0 }
        return min(10 * pow(2, Double(failures - 1)), 900)
    }
}

enum ContentVersion {
    /// Compares versions such as "2026.09.1" and "2026.10.12" number by number.
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = candidate.split(separator: ".").map { Int($0) ?? 0 }
        let b = current.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(a.count, b.count) {
            let left = index < a.count ? a[index] : 0
            let right = index < b.count ? b[index] : 0
            if left != right { return left > right }
        }
        return false
    }
}

extension JSONEncoder {
    static var api: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
