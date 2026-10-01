import Foundation
import Testing
@testable import SPAG_Buddy_Home

/// SPAG Buddy Home must stay strictly on-device. These fail if school code is ever built into it.
@MainActor
struct HomeEditionTests {
    /// Every type that lives in `SPAGSchoolSync`, plus the old name of `GrownUpGateView`.
    private static let schoolSyncTypeNames = [
        "APIClient", "APIError", "APIErrorBody", "AssignmentDTO", "AssignmentsResponse",
        "AttemptBatch", "AttemptUpload", "AttemptUploadResponse", "ContentUpdater", "ContentVersion",
        "JoinClassView", "JoinDetails", "JoinRequest", "JoinResponse", "KeychainStore",
        "RemoteContentManifest", "SchoolServices", "SyncPlanner", "SyncService", "TeacherGateView",
    ]

    @Test func editionIsHome() {
        #expect(Edition.current == .home)
    }

    @Test func schoolSyncIsNotLinked() {
        #if canImport(SPAGSchoolSync)
        Issue.record("The SPAGSchoolSync module can be imported from the Home tests")
        #endif
        let loaded = Bundle.allFrameworks.map(\.bundleURL.lastPathComponent)
        #expect(!loaded.contains { $0.hasPrefix("SPAGSchoolSync") }, "Loaded frameworks: \(loaded)")
    }

    @Test func noSchoolSyncTypeIsReachable() {
        let module = String(reflecting: Edition.self).split(separator: ".")[0]
        #expect(module == "SPAG_Buddy_Home")
        for name in Self.schoolSyncTypeNames {
            #expect(Self.type(named: name, in: String(module)) == nil, "\(module).\(name) is compiled into Home")
            #expect(Self.type(named: name, in: "SPAGSchoolSync") == nil, "SPAGSchoolSync.\(name) is loaded in Home")
        }
    }

    @Test func appHasNoClassFeatures() {
        #expect(AppModel.preview.classServices == nil)
    }

    @Test func infoPlistHandlesNoLinksAndHasNoServer() {
        let info = Bundle.main.infoDictionary ?? [:]
        #expect(info["CFBundleURLTypes"] == nil)
        #expect(info["SPAGBuddyAPIBaseURL"] == nil)
        #expect(info["NSAppTransportSecurity"] == nil)
    }

    @Test func privacyManifestDeclaresNoCollectionAndNoTracking() throws {
        let url = try #require(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
        let manifest = try #require(plist as? [String: Any])
        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        #expect((manifest["NSPrivacyTrackingDomains"] as? [Any])?.isEmpty == true)
        #expect((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true)
    }

    @Test func contentComesOnlyFromTheAppBundle() async throws {
        let bundled = try ContentLibrary.loadBundled()
        #expect(!bundled.questions.isEmpty)
        let app = AppModel(content: bundled, classServices: nil)
        await app.start()
        #expect(app.content.manifest.contentVersion == bundled.manifest.contentVersion)
    }

    /// Looks a type up by its mangled name, the way the Swift runtime would. Generic views are tried with `EmptyView`.
    private static func type(named name: String, in module: String) -> Any.Type? {
        let prefix = "\(module.utf8.count)\(module)\(name.utf8.count)\(name)"
        let candidates = ["V", "C", "O", "Vy7SwiftUI9EmptyViewVG", "Vy7SwiftUI7AnyViewVG"]
        for suffix in candidates {
            if let type = _typeByName(prefix + suffix) { return type }
        }
        return nil
    }
}
