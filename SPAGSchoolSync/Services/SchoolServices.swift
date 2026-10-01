import Foundation
import Observation
import SwiftData
import SwiftUI

/// SPAG Buddy School's class features: joining with a login card, sending answers and downloading new content.
@Observable
final class SchoolServices: ClassServices {
    /// A class login that arrived from a scanned QR code and is waiting to be completed.
    var pendingJoin: JoinDetails?

    @ObservationIgnored private let api: APIClient?
    @ObservationIgnored private let sync: SyncService

    init(api: APIClient? = APIClient.live, container: ModelContainer) {
        self.api = api
        sync = SyncService(api: api, container: container)
    }

    var lastError: String? { sync.lastError }

    func start() async {
        sync.start()
        await sync.syncAll()
    }

    func syncNow(pupil: PupilProfile) async {
        await sync.syncNow(pupil: pupil)
    }

    func forget(pupil: PupilProfile) {
        KeychainStore.deleteToken(for: pupil.id)
    }

    func updatedContent(current: ContentLibrary) async -> ContentLibrary? {
        guard let api else { return nil }
        return await ContentUpdater.update(using: api, currentVersion: current.manifest.contentVersion)
    }

    func joinClassView() -> AnyView {
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
