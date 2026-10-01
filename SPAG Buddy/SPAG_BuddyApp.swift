//
//  SPAG_BuddyApp.swift
//  SPAG Buddy
//
//  Created by Nathan Shipston on 11/02/2026.
//

import Foundation
import SwiftData
import SwiftUI

/// SPAG Buddy School. Built from `SPAGCore` and `SPAGSchoolSync`.
@main
struct SPAG_BuddyApp: App {
    private static let modelContainer = PupilStore.makeContainer()

    @State private var school: SchoolServices
    @State private var appModel: AppModel

    init() {
        let school = SchoolServices(container: Self.modelContainer)
        _school = State(initialValue: school)
        _appModel = State(initialValue: AppModel(content: Self.loadContent(), classServices: school))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .sheet(item: $school.pendingJoin) { details in
                    NavigationStack {
                        JoinClassView(prefilled: details)
                    }
                }
                .onOpenURL { school.handle(url: $0) }
                .environment(appModel)
        }
        .modelContainer(Self.modelContainer)
    }

    /// Uses downloaded content when it is newer than the content shipped in the app.
    private static func loadContent() -> ContentLibrary {
        let bundled = ContentLibrary.bundledForLaunch()
        return ContentUpdater.loadDownloadedContent(newerThan: bundled.manifest.contentVersion) ?? bundled
    }
}
