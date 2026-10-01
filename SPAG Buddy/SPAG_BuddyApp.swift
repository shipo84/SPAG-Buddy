//
//  SPAG_BuddyApp.swift
//  SPAG Buddy
//
//  Created by Nathan Shipston on 11/02/2026.
//

import Foundation
import SwiftData
import SwiftUI

@main
struct SPAG_BuddyApp: App {
    static let schema = Schema([PupilProfile.self, Attempt.self, Assignment.self, BadgeProgress.self])
    private static let modelContainer = makeModelContainer()

    @State private var appModel = AppModel(content: Self.loadContent(), container: Self.modelContainer)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .onOpenURL { appModel.handle(url: $0) }
        }
        .modelContainer(Self.modelContainer)
    }

    /// Pupil data stays on this device (and our server when in a class). It is never synced to iCloud.
    private static func makeModelContainer() -> ModelContainer {
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

    /// School uses downloaded content when it is newer than the content shipped in the app.
    /// Home only ever uses the bundled content, because it never downloads anything.
    private static func loadContent() -> ContentLibrary {
        let bundled: ContentLibrary
        do {
            bundled = try ContentLibrary.loadBundled()
        } catch {
            fatalError("Bundled content is invalid. Run the unit tests to find the problem: \(error)")
        }
        guard Edition.current.isSchool else { return bundled }
        return ContentUpdater.loadDownloadedContent(newerThan: bundled.manifest.contentVersion) ?? bundled
    }
}
