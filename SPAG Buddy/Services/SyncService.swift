import Foundation
import Network
import Observation
import SwiftData
import UIKit

/// Uploads answers and downloads assignments for pupils who are in a class.
///
/// Answers are always saved locally first. Uploads run when the app opens, after each session,
/// when the network comes back, and on pull-to-refresh. Each answer carries a client id so a
/// retried upload is never counted twice.
@Observable
final class SyncService {
    private(set) var isSyncing = false
    private(set) var lastError: String?

    @ObservationIgnored private let api: APIClient?
    @ObservationIgnored private let container: ModelContainer
    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private var consecutiveFailures = 0
    @ObservationIgnored private var nextAttemptAllowed = Date.distantPast
    @ObservationIgnored private var started = false

    init(api: APIClient?, container: ModelContainer) {
        self.api = api
        self.container = container
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
        for pupil in pupils {
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
        guard let token = KeychainStore.token(for: pupil.id) else {
            lastError = "This iPad needs to join the class again. Ask your teacher for a login card."
            return
        }

        isSyncing = true
        defer { isSyncing = false }
        let context = container.mainContext

        do {
            let pending = pupil.attempts.filter(\.needsSync)
            let byId = Dictionary(uniqueKeysWithValues: pending.map { ($0.id, $0) })
            for batch in SyncPlanner.batches(pending.map(\.upload)) {
                let response = try await api.uploadAttempts(batch, token: token)
                for id in response.settledIds {
                    byId[id]?.needsSync = false
                }
                try? context.save()
            }

            let remote = try await api.assignments(token: token)
            reconcile(assignments: remote, for: pupil, context: context)

            pupil.lastSyncedAt = .now
            try? context.save()
            consecutiveFailures = 0
            nextAttemptAllowed = .distantPast
            lastError = nil
        } catch APIError.unauthorised {
            lastError = "This iPad is no longer linked to \(pupil.className ?? "the class"). Answers are kept here. Ask your teacher for help."
        } catch {
            consecutiveFailures += 1
            nextAttemptAllowed = .now.addingTimeInterval(SyncPlanner.retryDelay(afterFailures: consecutiveFailures))
            lastError = "Couldn't send work just now. It will try again automatically."
        }
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
