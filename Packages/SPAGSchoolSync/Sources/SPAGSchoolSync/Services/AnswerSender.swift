import Foundation

/// `POST /attempts`, so tests can stand in for the server.
protocol AttemptUploading {
    func uploadAttempts(_ attempts: [AttemptUpload], token: String) async throws -> AttemptUploadResponse
}

extension APIClient: AttemptUploading {}

/// Sends a pupil's queued answers in batches and deletes each one once the server confirms it.
/// Unconfirmed answers stay queued and are resent with the same client id, which the server
/// ignores if it already has.
struct AnswerSender {
    enum Outcome: Equatable {
        case finished
        /// The server no longer accepts this pupil's device token.
        case cardRevoked
        /// Offline or a server error. Try again later.
        case failed
    }

    struct Report: Equatable {
        var sent: Set<UUID>
        var outcome: Outcome
    }

    var api: any AttemptUploading
    var queue: AnswerQueue

    func send(for pupilId: UUID, token: String) async -> Report {
        var sent = Set<UUID>()
        for batch in SyncPlanner.batches(queue.pending(for: pupilId)) {
            do {
                let response = try await api.uploadAttempts(batch, token: token)
                let confirmed = response.settledIds.intersection(batch.map(\.clientAttemptId))
                queue.remove(confirmed, for: pupilId)
                sent.formUnion(confirmed)
            } catch APIError.unauthorised {
                return Report(sent: sent, outcome: .cardRevoked)
            } catch {
                return Report(sent: sent, outcome: .failed)
            }
        }
        return Report(sent: sent, outcome: .finished)
    }
}
