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

    /// Removes anything kept for the pupil outside SwiftData before the profile is deleted.
    func forget(pupil: PupilProfile)

    /// Newer content than `current`, when an update was installed.
    func updatedContent(current: ContentLibrary) async -> ContentLibrary?

    /// The class code, picture and PIN login screen.
    func makeJoinClassView() -> AnyView
}
