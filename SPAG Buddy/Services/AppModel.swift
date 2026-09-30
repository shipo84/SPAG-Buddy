import Foundation
import Observation

/// App-wide state shared through the SwiftUI environment.
@Observable
final class AppModel {
    private static let activePupilKey = "activePupilID"

    private(set) var content: ContentLibrary
    let speech = SpeechService()

    var activePupilID: UUID? {
        didSet { UserDefaults.standard.set(activePupilID?.uuidString, forKey: Self.activePupilKey) }
    }

    /// A class login that arrived from a scanned QR code and is waiting to be completed.
    var pendingJoin: JoinDetails?

    init(content: ContentLibrary) {
        self.content = content
        activePupilID = UserDefaults.standard.string(forKey: Self.activePupilKey).flatMap(UUID.init(uuidString:))
    }

    func replaceContent(with library: ContentLibrary) {
        content = library
    }

    /// Handles `spagbuddy://join?class=ABC123&picture=fox&pin=1234` from a login card QR code.
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
