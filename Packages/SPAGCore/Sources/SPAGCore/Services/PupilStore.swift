import Foundation
import SwiftData

/// The on-device SwiftData store for pupil profiles and answers.
public enum PupilStore {
    public static let schema = Schema([PupilProfile.self, Attempt.self, Assignment.self, BadgeProgress.self])

    /// Pupil data stays on this device (and our server when in a class). It is never synced to iCloud.
    public static func makeContainer(for edition: Edition) -> ModelContainer {
        let url = storeURL(for: edition)
        moveLegacyStoreIfNeeded(for: edition, to: url)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
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

    private static var directory: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func storeURL(for edition: Edition) -> URL {
        directory.appendingPathComponent(edition.storeFileName)
    }

    /// Renames the store from before the split so existing Home users keep their pupils.
    private static func moveLegacyStoreIfNeeded(for edition: Edition, to url: URL) {
        guard let legacyName = edition.legacyStoreFileName else { return }
        let fileManager = FileManager.default
        let legacy = directory.appendingPathComponent(legacyName)
        guard fileManager.fileExists(atPath: legacy.path), !fileManager.fileExists(atPath: url.path) else { return }
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: legacy.path + suffix)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            try? fileManager.moveItem(at: source, to: URL(fileURLWithPath: url.path + suffix))
        }
    }
}
