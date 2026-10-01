import Foundation
import SwiftUI

/// Class features that only the School app provides: answer sync, assignments, remote content
/// and joining a class. The Home app passes no implementation, so none of that code is linked into it.
@MainActor
public protocol ClassServices: AnyObject {
    /// A message for grown-ups when the last sync failed.
    var lastError: String? { get }

    /// Called once when the app opens.
    func start() async

    /// Syncs straight away, ignoring any retry wait.
    func syncNow(pupil: PupilProfile) async

    /// Queues a new answer to be sent to the teacher.
    func record(_ attempt: Attempt, for pupil: PupilProfile)

    /// Answers on this iPad that the server has not confirmed yet.
    func unsentCount(for pupil: PupilProfile) -> Int

    /// Signs the pupil out and deletes their login and unsent answers from this iPad.
    func switchPupil(_ pupil: PupilProfile)

    /// Removes anything kept for the pupil outside SwiftData before the profile is deleted.
    func forget(pupil: PupilProfile)

    /// Newer content than `current`, when an update was installed.
    func updatedContent(current: ContentLibrary) async -> ContentLibrary?

    /// The whole screen shown when nobody is signed in. It replaces the Home app's welcome
    /// screen and pupil picker.
    func makeSignedOutView() -> AnyView
}
