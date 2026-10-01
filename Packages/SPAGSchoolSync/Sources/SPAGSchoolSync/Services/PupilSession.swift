import Foundation
import Observation

/// Signing pupils in and out on a shared class iPad.
@Observable
final class PupilSession {
    enum Notice: Equatable {
        case cardRevoked

        var message: String {
            switch self {
            case .cardRevoked: "Ask your teacher for a new login card."
            }
        }
    }

    let credentials: PupilCredentialStore
    @ObservationIgnored let queue: AnswerQueue
    /// Shown on the join screen after the server signed the pupil out.
    var notice: Notice?

    init(credentials: PupilCredentialStore, queue: AnswerQueue) {
        self.credentials = credentials
        self.queue = queue
    }

    func signIn(pupilId: UUID, deviceToken: String) throws {
        try credentials.saveToken(deviceToken, for: pupilId)
        credentials.activePupilID = pupilId
        notice = nil
    }

    func unsentCount(for pupilId: UUID) -> Int {
        queue.count(for: pupilId)
    }

    /// "Switch pupil": signs the pupil out and deletes their token and unsent answers from this iPad.
    /// Ask first when `unsentCount(for:)` is not zero.
    func switchPupil(_ pupilId: UUID) {
        queue.removeAll(for: pupilId)
        signOut(pupilId)
    }

    /// The server no longer accepts the pupil's card. Unsent answers are kept, so they are sent
    /// once the pupil joins again with a new card.
    func cardRevoked(_ pupilId: UUID) {
        let wasActive = credentials.activePupilID == pupilId
        signOut(pupilId)
        if wasActive { notice = .cardRevoked }
    }

    func signOut(_ pupilId: UUID) {
        credentials.deleteToken(for: pupilId)
        if credentials.activePupilID == pupilId { credentials.activePupilID = nil }
    }
}
