//
//  SPAGHomeApp.swift
//  SPAG Buddy Home
//
//  Created by Nathan Shipston on 11/02/2026.
//

import Foundation
import SPAGCore
import SwiftData
import SwiftUI

@main
struct SPAGHomeApp: App {
    private static let edition = Edition.home
    private static let modelContainer = PupilStore.makeContainer(for: edition)

    @State private var appModel = AppModel(content: Self.loadContent())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .environment(\.edition, Self.edition)
        }
        .modelContainer(Self.modelContainer)
    }

    private static func loadContent() -> ContentLibrary {
        do {
            return try ContentLibrary.loadBundled()
        } catch {
            fatalError("Bundled content is invalid. Run the unit tests to find the problem: \(error)")
        }
    }
}
