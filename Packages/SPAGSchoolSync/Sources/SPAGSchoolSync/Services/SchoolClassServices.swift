import Foundation
import Observation
import SPAGCore
import SwiftData
import SwiftUI

/// The School app's class features: answer sync, assignments, remote content and joining a class.
@Observable
public final class SchoolClassServices: ClassServices {
    /// A class login that arrived from a scanned QR code and is waiting to be completed.
    var pendingJoin: JoinDetails?

    @ObservationIgnored private let api: APIClient?
    @ObservationIgnored private let sync: SyncService

    public convenience init(container: ModelContainer) {
        self.init(api: APIClient.live, container: container)
    }

    init(api: APIClient?, container: ModelContainer) {
        self.api = api
        sync = SyncService(api: api, container: container)
    }

    public var lastError: String? { sync.lastError }

    public func start() async {
        sync.start()
        await sync.syncAll()
    }

    public func syncNow(pupil: PupilProfile) async {
        await sync.syncNow(pupil: pupil)
    }

    public func forget(pupil: PupilProfile) {
        KeychainStore.deleteToken(for: pupil.id)
    }

    public func updatedContent(current: ContentLibrary) async -> ContentLibrary? {
        guard let api else { return nil }
        return await ContentUpdater.update(using: api, currentVersion: current.manifest.contentVersion)
    }

    public func makeJoinClassView() -> AnyView {
        AnyView(JoinClassView())
    }

    /// Handles `spagbuddy://join?class=ABC234&picture=fox&pin=4821` from a login card QR code.
    func handle(url: URL) {
        guard url.scheme == "spagbuddy", url.host == "join",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else { return }
        let value = { (name: String) in items.first { $0.name == name }?.value ?? "" }
        pendingJoin = JoinDetails(classCode: value("class"), avatarKey: value("picture"), pin: value("pin"))
    }
}

struct JoinDetails: Identifiable, Hashable {
    var classCode: String
    var avatarKey: String
    var pin: String

    var id: String { classCode + avatarKey }
}
