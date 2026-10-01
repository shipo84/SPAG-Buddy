#if DEBUG
import Foundation
import SwiftData

extension ModelContainer {
    static let preview: ModelContainer = {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: PupilStore.schema, configurations: configuration)
            let pupil = PupilProfile(displayName: "Mia", avatarKey: "fox", yearGroup: 4)
            pupil.stars = 42
            pupil.currentStreak = 3
            pupil.lastPracticeDay = .now
            container.mainContext.insert(pupil)
            return container
        } catch {
            fatalError("Preview container failed: \(error)")
        }
    }()
}

extension AppModel {
    static var preview: AppModel {
        do {
            return AppModel(content: try ContentLibrary.loadBundled())
        } catch {
            fatalError("Preview content failed to load: \(error)")
        }
    }
}
#endif
