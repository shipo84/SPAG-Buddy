import Foundation
import Observation
import SwiftData

/// App-wide state shared through the SwiftUI environment.
@Observable
final class AppModel {
    private static let activePupilKey = "activePupilID"

    private(set) var content: ContentLibrary
    let speech = SpeechService()
    let sync: SyncService

    var activePupilID: UUID? {
        didSet { UserDefaults.standard.set(activePupilID?.uuidString, forKey: Self.activePupilKey) }
    }

    /// A class login that arrived from a scanned QR code and is waiting to be completed.
    var pendingJoin: JoinDetails?

    init(content: ContentLibrary, container: ModelContainer, api: APIClient? = APIClient.live) {
        self.content = content
        sync = SyncService(api: api, container: container)
        activePupilID = UserDefaults.standard.string(forKey: Self.activePupilKey).flatMap(UUID.init(uuidString:))
    }

    func start() async {
        sync.start()
        await sync.syncAll()
        if let api = APIClient.live,
           let updated = await ContentUpdater.update(using: api, currentVersion: content.manifest.contentVersion) {
            content = updated
        }
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
