import Foundation
import Testing
@testable import SPAGSchoolSync
#if canImport(Security)
import Security
#endif

@MainActor
struct TokenStorageTests {
    private let pupil = UUID()

    @Test func tokensAreSavedPerPupil() throws {
        let store = PupilCredentialStore(secureStore: InMemorySecureStore(), defaults: TestSupport.defaults())
        let other = UUID()
        try store.saveToken("token-a", for: pupil)
        try store.saveToken("token-b", for: other)

        #expect(store.token(for: pupil) == "token-a")
        #expect(store.token(for: other) == "token-b")
        #expect(store.token(for: UUID()) == nil)
    }

    @Test func savingAgainReplacesTheToken() throws {
        let store = PupilCredentialStore(secureStore: InMemorySecureStore(), defaults: TestSupport.defaults())
        try store.saveToken("old", for: pupil)
        try store.saveToken("new", for: pupil)
        #expect(store.token(for: pupil) == "new")
    }

    @Test func deletingATokenLeavesOtherPupilsSignedIn() throws {
        let store = PupilCredentialStore(secureStore: InMemorySecureStore(), defaults: TestSupport.defaults())
        let other = UUID()
        try store.saveToken("token-a", for: pupil)
        try store.saveToken("token-b", for: other)

        store.deleteToken(for: pupil)

        #expect(!store.hasToken(for: pupil))
        #expect(store.token(for: other) == "token-b")
    }

    @Test func tokensAndActivePupilAreKeptInTheSecureStore() throws {
        let secure = InMemorySecureStore()
        let (defaults, suiteName) = TestSupport.suite()
        let store = PupilCredentialStore(secureStore: secure, defaults: defaults)
        try store.saveToken("secret-device-token", for: pupil)
        store.activePupilID = pupil

        #expect(secure.values[PupilCredentialStore.tokenKey(pupil)] == Data("secret-device-token".utf8))
        #expect(secure.values[PupilCredentialStore.activePupilKey] == Data(pupil.uuidString.utf8))

        // The only thing written to UserDefaults is the install marker.
        #expect(defaults.persistentDomain(forName: suiteName)?.keys.sorted() == [PupilCredentialStore.installMarkerKey])
        let everything = defaults.dictionaryRepresentation().values.map { "\($0)" }.joined(separator: "\n")
        #expect(!everything.contains("secret-device-token"))
        #expect(!everything.contains(pupil.uuidString))
        #expect(UserDefaults.standard.object(forKey: "activePupilID") == nil)
    }

    @Test func activePupilIsRememberedAfterARelaunch() {
        let secure = InMemorySecureStore()
        let defaults = TestSupport.defaults()
        PupilCredentialStore(secureStore: secure, defaults: defaults).activePupilID = pupil

        let relaunched = PupilCredentialStore(secureStore: secure, defaults: defaults)
        #expect(relaunched.activePupilID == pupil)

        relaunched.activePupilID = nil
        #expect(secure.values[PupilCredentialStore.activePupilKey] == nil)
        #expect(PupilCredentialStore(secureStore: secure, defaults: defaults).activePupilID == nil)
    }

    /// Keychain items outlive the app, so a reinstalled app must not find the previous school's logins.
    @Test func aFreshInstallStartsSignedOut() throws {
        let secure = InMemorySecureStore()
        try secure.set(Data("left-over".utf8), forKey: PupilCredentialStore.tokenKey(pupil))
        try secure.set(Data(pupil.uuidString.utf8), forKey: PupilCredentialStore.activePupilKey)

        let store = PupilCredentialStore(secureStore: secure, defaults: TestSupport.defaults())

        #expect(store.activePupilID == nil)
        #expect(store.token(for: pupil) == nil)
        #expect(secure.values.isEmpty)
    }

    @Test func anExistingInstallKeepsItsLogins() throws {
        let secure = InMemorySecureStore()
        let defaults = TestSupport.defaults()
        let first = PupilCredentialStore(secureStore: secure, defaults: defaults)
        try first.saveToken("token", for: pupil)

        let relaunched = PupilCredentialStore(secureStore: secure, defaults: defaults)
        #expect(relaunched.token(for: pupil) == "token")
    }

    @Test func keychainItemsAreReadableAfterFirstUnlockOnThisDeviceOnly() throws {
        #if canImport(Security)
        let attributes = KeychainStore.itemAttributes(Data("token".utf8))
        let accessible = try #require(attributes[kSecAttrAccessible as String] as? String)
        #expect(accessible == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
        #endif
    }

    #if canImport(Security)
    /// Uses the real Keychain under a service name of its own.
    @Test func keychainRoundTripStoresTheProtectionClass() throws {
        let keychain = KeychainStore(service: "Digital-Clubhouse.SPAG-Buddy-School.tests.\(UUID().uuidString)")
        defer { try? keychain.removeAll() }
        let store = PupilCredentialStore(secureStore: keychain, defaults: TestSupport.defaults())

        try store.saveToken("token-1", for: pupil)
        try store.saveToken("token-2", for: pupil)
        store.activePupilID = pupil

        #expect(store.token(for: pupil) == "token-2")
        #expect(try keychain.accessibility(forKey: PupilCredentialStore.tokenKey(pupil)) == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
        #expect(try keychain.accessibility(forKey: PupilCredentialStore.activePupilKey) == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)

        store.deleteToken(for: pupil)
        #expect(store.token(for: pupil) == nil)
    }

    @Test func clearingTheKeychainOnlyTouchesThisAppsService() throws {
        let mine = KeychainStore(service: "Digital-Clubhouse.SPAG-Buddy-School.tests.\(UUID().uuidString)")
        let other = KeychainStore(service: "Digital-Clubhouse.SPAG-Buddy-School.tests.\(UUID().uuidString)")
        defer {
            try? mine.removeAll()
            try? other.removeAll()
        }
        try mine.set(Data("a".utf8), forKey: "key")
        try other.set(Data("b".utf8), forKey: "key")

        try mine.removeAll()

        #expect(try mine.data(forKey: "key") == nil)
        #expect(try other.data(forKey: "key") == Data("b".utf8))
    }
    #endif
}
