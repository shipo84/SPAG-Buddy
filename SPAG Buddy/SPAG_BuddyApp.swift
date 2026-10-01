//
//  SPAG_BuddyApp.swift
//  SPAG Buddy Home
//
//  Created by Nathan Shipston on 11/02/2026.
//

import Foundation
import SwiftData
import SwiftUI

@main
struct SPAG_BuddyApp: App {
    static let schema = Schema([PupilProfile.self, Attempt.self, BadgeProgress.self])
    private static let modelContainer = makeModelContainer()

    @State private var appModel = AppModel(content: Self.loadContent())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
        }
        .modelContainer(Self.modelContainer)
    }

    /// Pupil data stays on this device. It is never synced to iCloud or sent to a server.
    private static func makeModelContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // A store that cannot be opened (for example after an incompatible model change) is reset
            // rather than crashing the app. Progress on this device is lost in that case.
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

    /// Home only ever uses the content shipped inside the app.
    private static func loadContent() -> ContentLibrary {
        do {
            return try ContentLibrary.loadBundled()
        } catch {
            fatalError("Bundled content is invalid. Run the unit tests to find the problem: \(error)")
        }
    }
}
