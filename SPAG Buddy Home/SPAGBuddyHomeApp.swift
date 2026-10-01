import SwiftData
import SwiftUI

/// SPAG Buddy Home. Built from `SPAGCore` only: everything stays on this device.
///
/// It never links `SPAGSchoolSync`, uses only the content bundled in the app and has no class features.
/// `Scripts/check-home-on-device.sh` fails the build if networking code is added.
@main
struct SPAGBuddyHomeApp: App {
    private static let modelContainer = PupilStore.makeContainer()

    @State private var appModel = AppModel(content: .bundledForLaunch(), classServices: nil)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
        }
        .modelContainer(Self.modelContainer)
    }
}
