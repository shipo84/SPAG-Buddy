import Foundation
import Network
import Observation
import SPAGCore
import SwiftData
import UIKit

/// Uploads answers and downloads assignments for pupils who are signed in to a class.
///
/// Every answer goes into the `AnswerQueue` as soon as it is marked. Uploads run when the app
/// opens, after each session, when the network comes back, and on pull-to-refresh. Each answer
/// carries a client id so a retried upload is never counted twice.
@Observable
final class SyncService {
    private(set) var isSyncing = false
    private(set) var lastError: String?

    @ObservationIgnored private let api: APIClient?
    @ObservationIgnored private let container: ModelContainer
    @ObservationIgnored private let session: PupilSession
    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private var consecutiveFailures = 0
    @ObservationIgnored private var nextAttemptAllowed = Date.distantPast
    @ObservationIgnored private var started = false

    init(api: APIClient?, container: ModelContainer, session: PupilSession) {
        self.api = api
        self.container = container
        self.session = session
    }

    var isEnabled: Bool { api != nil }

    func start() {
        guard api != nil, !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }
            Task { @MainActor in await self?.syncAll() }
        }
        monitor.start(queue: DispatchQueue(label: "spag-buddy.network"))
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in await self?.syncAll() }
        }
    }

    func syncAll() async {
        let descriptor = FetchDescriptor<PupilProfile>(predicate: #Predicate { $0.remotePupilId != nil })
        guard let pupils = try? container.mainContext.fetch(descriptor) else { return }
        for pupil in pupils where session.credentials.hasToken(for: pupil.id) {
            await sync(pupil: pupil, force: false)
        }
    }

    /// Syncs straight away, ignoring any retry wait.
    func syncNow(pupil: PupilProfile) async {
        await sync(pupil: pupil, force: true)
    }

    private func sync(pupil: PupilProfile, force: Bool) async {
        guard let api, pupil.isInClass, !isSyncing else { return }
        guard force || Date.now >= nextAttemptAllowed else { return }
        guard let token = session.credentials.token(for: pupil.id) else {
            session.signOut(pupil.id)
            return
        }

        isSyncing = true
        defer { isSyncing = false }
        let context = container.mainContext
        queueMissingAnswers(of: pupil)

        let report = await AnswerSender(api: api, queue: session.queue).send(for: pupil.id, token: token)
        for attempt in pupil.attempts where report.sent.contains(attempt.id) {
            attempt.needsSync = false
        }
        try? context.save()

        switch report.outcome {
        case .finished: break
        case .cardRevoked: return cardRevoked(pupil)
        case .failed: return backOff()
        }

        do {
            let remote = try await api.assignments(token: token)
            reconcile(assignments: remote, for: pupil, context: context)
            pupil.lastSyncedAt = .now
            try? context.save()
            consecutiveFailures = 0
            nextAttemptAllowed = .distantPast
            lastError = nil
        } catch APIError.unauthorised {
            cardRevoked(pupil)
        } catch {
            backOff()
        }
    }

    /// Covers an answer whose queue file could not be written when it was marked.
    private func queueMissingAnswers(of pupil: PupilProfile) {
        for attempt in pupil.attempts where attempt.needsSync && !session.queue.contains(attempt.id, for: pupil.id) {
            try? session.queue.add(attempt.upload, for: pupil.id)
        }
    }

    private func cardRevoked(_ pupil: PupilProfile) {
        session.cardRevoked(pupil.id)
        lastError = "\(pupil.displayName)'s login card no longer works. \(PupilSession.Notice.cardRevoked.message)"
    }

    private func backOff() {
        consecutiveFailures += 1
        nextAttemptAllowed = .now.addingTimeInterval(SyncPlanner.retryDelay(afterFailures: consecutiveFailures))
        lastError = "Couldn't send work just now. It will try again automatically."
    }

    private func reconcile(assignments remote: [AssignmentDTO], for pupil: PupilProfile, context: ModelContext) {
        let remoteIds = Set(remote.map(\.id))
        for local in pupil.assignments where !remoteIds.contains(local.remoteId) {
            context.delete(local)
        }
        for item in remote {
            if let existing = pupil.assignments.first(where: { $0.remoteId == item.id }) {
                existing.title = item.title
                existing.objectiveCodes = item.objectiveCodes
                existing.spellingListId = item.spellingListId
                existing.dueDate = item.dueDateValue
                existing.fetchedAt = .now
            } else {
                context.insert(Assignment(
                    remoteId: item.id,
                    pupil: pupil,
                    title: item.title,
                    objectiveCodes: item.objectiveCodes,
                    spellingListId: item.spellingListId,
                    dueDate: item.dueDateValue
                ))
            }
        }
    }
}

extension Attempt {
    var upload: AttemptUpload {
        AttemptUpload(
            clientAttemptId: id,
            questionId: questionId,
            correct: correct,
            answerGiven: answerGiven,
            timeTakenMs: timeTakenMs,
            hintUsed: hintUsed,
            sessionId: sessionId,
            sessionKind: sessionKind,
            assignmentId: assignmentId,
            answeredAt: answeredAt
        )
    }
}
