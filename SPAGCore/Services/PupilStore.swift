import Foundation
import SwiftData

/// The on-device SwiftData store. Each app has its own copy in its own sandbox, and it is never synced to iCloud.
enum PupilStore {
    static let schema = Schema([PupilProfile.self, Attempt.self, Assignment.self, BadgeProgress.self])

    static func makeContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // A store that cannot be opened (for example after an incompatible model change) is reset
            // rather than crashing the app. Unsynced work on this device is lost in that case.
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: configuration.url.path + suffix))
            }
            if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
                return container
            }
            let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            do {
                return try ModelContainer(for: schema, configurations: [memory])
            } catch {
                fatalError("Could not create an in-memory ModelContainer: \(error)")
            }
        }
    }
}

extension ContentLibrary {
    /// The content shipped inside the app. Bundled content that does not load is a build mistake, so this stops the app.
    static func bundledForLaunch() -> ContentLibrary {
        do {
            return try loadBundled()
        } catch {
            fatalError("Bundled content is invalid. Run the unit tests to find the problem: \(error)")
        }
    }
}
