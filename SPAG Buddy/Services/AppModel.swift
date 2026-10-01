import Foundation
import Observation
import SwiftData

/// App-wide state shared through the SwiftUI environment.
@Observable
final class AppModel {
    private static let activePupilKey = "activePupilID"

    /// Fixed for the life of the app. Home never creates the class services below.
    let edition: Edition
    private(set) var content: ContentLibrary
    let speech = SpeechService()
    /// Uploads answers and fetches assignments. `nil` in the Home edition, which has no class and never syncs.
    let sync: SyncService?

    var activePupilID: UUID? {
        didSet { UserDefaults.standard.set(activePupilID?.uuidString, forKey: Self.activePupilKey) }
    }

    /// A class login that arrived from a scanned QR code and is waiting to be completed. School only.
    var pendingJoin: JoinDetails?

    init(content: ContentLibrary, container: ModelContainer, edition: Edition = .current, api: APIClient? = APIClient.live) {
        self.edition = edition
        self.content = content
        sync = edition.isSchool ? SyncService(api: api, container: container) : nil
        activePupilID = UserDefaults.standard.string(forKey: Self.activePupilKey).flatMap(UUID.init(uuidString:))
    }

    func start() async {
        guard let sync else { return }
        sync.start()
        await sync.syncAll()
        if let api = APIClient.live,
           let updated = await ContentUpdater.update(using: api, currentVersion: content.manifest.contentVersion) {
            content = updated
        }
    }

    /// Handles `spagbuddy://join?class=ABC234&picture=fox&pin=4821` from a login card QR code.
    func handle(url: URL) {
        guard edition.isSchool, url.scheme == "spagbuddy", url.host == "join",
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
