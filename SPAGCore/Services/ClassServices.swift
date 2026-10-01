import Foundation
import SwiftUI

/// Everything a class adds on top of the shared app: joining, sending answers and downloading new content.
///
/// Only SPAG Buddy School provides this (in `SPAGSchoolSync`). SPAG Buddy Home passes `nil`, so the shared
/// views hide their class features and nothing in Home can reach a server.
protocol ClassServices: AnyObject {
    /// A message for grown-ups when work could not be sent.
    var lastError: String? { get }

    func start() async
    func syncNow(pupil: PupilProfile) async
    /// Called before a pupil is removed from this device.
    func forget(pupil: PupilProfile)
    /// Newer content, when the server has some.
    func updatedContent(current: ContentLibrary) async -> ContentLibrary?
    func joinClassView() -> AnyView
}
