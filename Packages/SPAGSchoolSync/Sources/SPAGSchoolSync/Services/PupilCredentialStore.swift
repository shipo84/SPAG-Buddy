import Foundation
import Observation

/// Each pupil's device token and which pupil is signed in. Both live in the secure store,
/// never in UserDefaults.
@Observable
final class PupilCredentialStore {
    static let activePupilKey = "active-pupil"
    /// A plain flag, not a secret. Keychain items survive deleting the app, so a reinstall
    /// would otherwise find the last school's tokens.
    static let installMarkerKey = "SPAGSchool.keychainBelongsToThisInstall"

    @ObservationIgnored private let secureStore: any SecureStore

    /// The pupil using the app. `nil` shows the join screen.
    var activePupilID: UUID? {
        didSet {
            guard activePupilID != oldValue else { return }
            if let activePupilID {
                try? secureStore.set(Data(activePupilID.uuidString.utf8), forKey: Self.activePupilKey)
            } else {
                try? secureStore.removeValue(forKey: Self.activePupilKey)
            }
        }
    }

    init(secureStore: any SecureStore, defaults: UserDefaults = .standard) {
        self.secureStore = secureStore
        if !defaults.bool(forKey: Self.installMarkerKey) {
            try? secureStore.removeAll()
            defaults.set(true, forKey: Self.installMarkerKey)
        }
        activePupilID = (try? secureStore.data(forKey: Self.activePupilKey))
            .flatMap { String(data: $0, encoding: .utf8) }
            .flatMap(UUID.init(uuidString:))
    }

    func token(for pupilId: UUID) -> String? {
        (try? secureStore.data(forKey: Self.tokenKey(pupilId))).flatMap { String(data: $0, encoding: .utf8) }
    }

    func hasToken(for pupilId: UUID) -> Bool {
        token(for: pupilId) != nil
    }

    func saveToken(_ token: String, for pupilId: UUID) throws {
        try secureStore.set(Data(token.utf8), forKey: Self.tokenKey(pupilId))
    }

    func deleteToken(for pupilId: UUID) {
        try? secureStore.removeValue(forKey: Self.tokenKey(pupilId))
    }

    static func tokenKey(_ pupilId: UUID) -> String {
        "device-token.\(pupilId.uuidString)"
    }
}
