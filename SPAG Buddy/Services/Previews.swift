#if DEBUG
import Foundation
import SwiftData

extension ModelContainer {
    /// One pupil, Mia, with a little progress.
    static let preview = makePreview { container in
        let pupil = PupilProfile(displayName: "Mia", avatarKey: "fox", yearGroup: 4)
        pupil.stars = 42
        pupil.currentStreak = 3
        pupil.lastPracticeDay = .now
        container.mainContext.insert(pupil)
    }

    /// Two children sharing one iPad, so the "Who is practising?" picker shows.
    static let previewFamily = makePreview { container in
        let mia = PupilProfile(displayName: "Mia", avatarKey: "fox", yearGroup: 4)
        mia.stars = 42
        let leo = PupilProfile(displayName: "Leo", avatarKey: "dragon", yearGroup: 2)
        leo.stars = 15
        container.mainContext.insert(mia)
        container.mainContext.insert(leo)
    }

    /// No pupils yet, so the app shows the welcome screen.
    static let previewEmpty = makePreview { _ in }

    private static func makePreview(populate: (ModelContainer) -> Void) -> ModelContainer {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: SPAG_BuddyApp.schema, configurations: configuration)
            populate(container)
            return container
        } catch {
            fatalError("Preview container failed: \(error)")
        }
    }
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
