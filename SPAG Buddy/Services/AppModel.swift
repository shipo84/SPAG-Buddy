import Foundation
import Observation
import SwiftData

/// App-wide state shared through the SwiftUI environment.
///
/// SPAG Buddy Home has no server, no class and no sync. Everything a pupil does stays on this device.
@Observable
final class AppModel {
    private static let activePupilKey = "activePupilID"

    let content: ContentLibrary
    let speech = SpeechService()

    var activePupilID: UUID? {
        didSet { UserDefaults.standard.set(activePupilID?.uuidString, forKey: Self.activePupilKey) }
    }

    init(content: ContentLibrary) {
        self.content = content
        activePupilID = UserDefaults.standard.string(forKey: Self.activePupilKey).flatMap(UUID.init(uuidString:))
    }
}
