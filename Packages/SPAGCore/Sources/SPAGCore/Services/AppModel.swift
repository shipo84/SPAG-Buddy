import Foundation
import Observation
import SwiftData

/// App-wide state shared through the SwiftUI environment.
@Observable
public final class AppModel {
    private static let activePupilKey = "activePupilID"

    public private(set) var content: ContentLibrary
    let speech = SpeechService()
    /// `nil` in the Home app, which has no class features.
    public let classServices: (any ClassServices)?

    public var activePupilID: UUID? {
        didSet { UserDefaults.standard.set(activePupilID?.uuidString, forKey: Self.activePupilKey) }
    }

    public init(content: ContentLibrary, classServices: (any ClassServices)? = nil) {
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
