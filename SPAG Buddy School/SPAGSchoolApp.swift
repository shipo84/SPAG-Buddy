//
//  SPAGSchoolApp.swift
//  SPAG Buddy School
//
//  Created by Nathan Shipston on 11/02/2026.
//

import Foundation
import SPAGCore
import SPAGSchoolSync
import SwiftData
import SwiftUI

@main
struct SPAGSchoolApp: App {
    private static let edition = Edition.school
    private static let modelContainer = PupilStore.makeContainer(for: edition)

    @State private var classServices: SchoolClassServices
    @State private var appModel: AppModel

    init() {
        let classServices = SchoolClassServices(container: Self.modelContainer)
        _classServices = State(initialValue: classServices)
        _appModel = State(initialValue: AppModel(
            content: Self.loadContent(),
            classServices: classServices,
            activePupilStore: classServices.activePupilStore
        ))
    }

    var body: some Scene {
        WindowGroup {
            SchoolRootView(classServices: classServices)
                .environment(appModel)
                .environment(\.edition, Self.edition)
        }
        .modelContainer(Self.modelContainer)
    }

    /// Uses downloaded content when it is newer than the content shipped in the app.
    private static func loadContent() -> ContentLibrary {
        let bundled: ContentLibrary
        do {
            bundled = try ContentLibrary.loadBundled()
        } catch {
            fatalError("Bundled content is invalid. Run the unit tests to find the problem: \(error)")
        }
        return ContentUpdater.loadDownloadedContent(newerThan: bundled.manifest.contentVersion) ?? bundled
    }
}
