import Foundation
import Observation
import SPAGCore
import SwiftData
import SwiftUI

/// The School app's class features: signing in with a login card, answer sync, assignments and remote content.
@Observable
public final class SchoolClassServices: ClassServices {
    private static let privacyNoticeSeenKey = "SPAGSchool.privacyNoticeSeen"

    /// A class login that arrived from a scanned QR code and is waiting to be completed.
    var pendingJoin: JoinDetails?
    let session: PupilSession

    /// The privacy notice is shown once on this iPad before the first join.
    var hasSeenPrivacyNotice: Bool {
        didSet { defaults.set(hasSeenPrivacyNotice, forKey: Self.privacyNoticeSeenKey) }
    }

    @ObservationIgnored let api: APIClient?
    @ObservationIgnored private let sync: SyncService
    @ObservationIgnored private let container: ModelContainer
    @ObservationIgnored private let defaults: UserDefaults

    public convenience init(container: ModelContainer) {
        self.init(api: APIClient.live, container: container, secureStore: KeychainStore(), queue: AnswerQueue(), defaults: .standard)
    }

    init(api: APIClient?, container: ModelContainer, secureStore: any SecureStore, queue: AnswerQueue, defaults: UserDefaults) {
        self.api = api
        self.container = container
        self.defaults = defaults
        session = PupilSession(credentials: PupilCredentialStore(secureStore: secureStore, defaults: defaults), queue: queue)
        sync = SyncService(api: api, container: container, session: session)
        hasSeenPrivacyNotice = defaults.bool(forKey: Self.privacyNoticeSeenKey)
    }

    /// Pass to `AppModel` so the signed-in pupil is remembered in the Keychain.
    public var activePupilStore: any ActivePupilStore { session.credentials }

    public var lastError: String? { sync.lastError }

    public func start() async {
        sync.start()
        await sync.syncAll()
    }

    public func syncNow(pupil: PupilProfile) async {
        await sync.syncNow(pupil: pupil)
    }

    public func record(_ attempt: Attempt, for pupil: PupilProfile) {
        guard pupil.isInClass else { return }
        try? session.queue.add(attempt.upload, for: pupil.id)
    }

    public func unsentCount(for pupil: PupilProfile) -> Int {
        session.unsentCount(for: pupil.id)
    }

    public func switchPupil(_ pupil: PupilProfile) {
        session.switchPupil(pupil.id)
        let context = container.mainContext
        for attempt in pupil.attempts where attempt.needsSync {
            context.delete(attempt)
        }
        try? context.save()
    }

    public func forget(pupil: PupilProfile) {
        session.switchPupil(pupil.id)
    }

    public func updatedContent(current: ContentLibrary) async -> ContentLibrary? {
        guard let api else { return nil }
        return await ContentUpdater.update(using: api, currentVersion: current.manifest.contentVersion)
    }

    public func makeSignedOutView() -> AnyView {
        AnyView(SchoolSignedOutView(classServices: self))
    }

    /// Handles `spagbuddy://join?...` from a login card QR code scanned with the Camera app.
    func handle(url: URL) {
        guard let details = JoinDetails(url: url) else { return }
        pendingJoin = details
    }

    /// Saves the pupil from a successful join and signs them in.
    func completeJoin(_ response: JoinResponse, existing pupils: [PupilProfile], context: ModelContext) throws {
        let pupil: PupilProfile
        if let existing = pupils.first(where: { $0.remotePupilId == response.pupilId }) {
            pupil = existing
        } else {
            pupil = PupilProfile(
                displayName: response.displayName,
                avatarKey: response.avatarKey,
                yearGroup: response.yearGroup,
                remotePupilId: response.pupilId,
                classCode: response.classCode,
                className: response.className
            )
            context.insert(pupil)
        }
        pupil.yearGroup = response.yearGroup
        pupil.className = response.className
        try context.save()
        try session.signIn(pupilId: pupil.id, deviceToken: response.deviceToken)
    }
}

extension PupilCredentialStore: ActivePupilStore {}
