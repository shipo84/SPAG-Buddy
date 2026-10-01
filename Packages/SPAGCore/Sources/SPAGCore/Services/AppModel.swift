import Foundation
import Observation
import SwiftData

/// App-wide state shared through the SwiftUI environment.
@Observable
public final class AppModel {
    public private(set) var content: ContentLibrary
    public let speech = SpeechService()
    /// `nil` in the Home app, which has no class features.
    public let classServices: (any ClassServices)?
    @ObservationIgnored private let activePupilStore: any ActivePupilStore

    public var activePupilID: UUID? {
        get { activePupilStore.activePupilID }
        set { activePupilStore.activePupilID = newValue }
    }

    public init(
        content: ContentLibrary,
        classServices: (any ClassServices)? = nil,
        activePupilStore: any ActivePupilStore = UserDefaultsActivePupilStore()
    ) {
        self.content = content
        self.classServices = classServices
        self.activePupilStore = activePupilStore
    }

    func start() async {
        guard let classServices else { return }
        await classServices.start()
        if let updated = await classServices.updatedContent(current: content) {
            content = updated
        }
    }
}
