import Foundation
import Observation

/// App-wide state shared through the SwiftUI environment.
@Observable
final class AppModel {
    private static let activePupilKey = "activePupilID"

    private(set) var content: ContentLibrary
    let speech = SpeechService()
    /// `nil` in SPAG Buddy Home, which has no class features.
    let classServices: (any ClassServices)?

    var activePupilID: UUID? {
        didSet { UserDefaults.standard.set(activePupilID?.uuidString, forKey: Self.activePupilKey) }
    }

    init(content: ContentLibrary, classServices: (any ClassServices)?) {
        self.content = content
        self.classServices = classServices
        activePupilID = UserDefaults.standard.string(forKey: Self.activePupilKey).flatMap(UUID.init(uuidString:))
    }

    func start() async {
        guard let classServices else { return }
        await classServices.start()
        if let updated = await classServices.updatedContent(current: content) {
            content = updated
        }
    }
}
