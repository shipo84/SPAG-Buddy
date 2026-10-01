#if DEBUG
import Foundation
import SwiftData

extension ModelContainer {
    /// One home pupil, Mia, with a little progress.
    static let preview = makePreview { container in
        let pupil = PupilProfile(displayName: "Mia", avatarKey: "fox", yearGroup: 4)
        pupil.stars = 42
        pupil.currentStreak = 3
        pupil.lastPracticeDay = .now
        container.mainContext.insert(pupil)
    }

    /// One class pupil, Sam, who joined Year 5 Owls with a login card.
    static let previewSchool = makePreview { container in
        let pupil = PupilProfile(
            displayName: "Sam",
            avatarKey: "owl",
            yearGroup: 5,
            remotePupilId: "preview-pupil",
            classCode: "OWL523",
            className: "Year 5 Owls"
        )
        pupil.stars = 118
        pupil.currentStreak = 6
        pupil.lastPracticeDay = .now
        pupil.sessionsCompleted = 12
        container.mainContext.insert(pupil)
        container.mainContext.insert(Assignment(
            remoteId: "preview-assignment",
            pupil: pupil,
            title: "Extra information in brackets",
            objectiveCodes: ["Y5-P-parenthesis"],
            spellingListId: nil,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: .now)
        ))
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
    static var preview: AppModel { preview(edition: .home) }

    static func preview(edition: Edition, container: ModelContainer = .preview) -> AppModel {
        do {
            return AppModel(content: try ContentLibrary.loadBundled(), container: container, edition: edition, api: nil)
        } catch {
            fatalError("Preview content failed to load: \(error)")
        }
    }
}
#endif
