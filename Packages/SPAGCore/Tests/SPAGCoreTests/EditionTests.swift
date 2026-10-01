import Foundation
import Testing
@testable import SPAGCore

@MainActor
struct EditionTests {
    @Test func eachEditionHasItsOwnStore() {
        #expect(Edition.home.storeFileName == "SPAGHome.store")
        #expect(Edition.school.storeFileName == "SPAGSchool.store")
        #expect(PupilStore.storeURL(for: .home) != PupilStore.storeURL(for: .school))
    }

    @Test func onlyHomeMovesTheStoreFromBeforeTheSplit() {
        #expect(Edition.home.legacyStoreFileName == "default.store")
        #expect(Edition.school.legacyStoreFileName == nil)
    }
}
