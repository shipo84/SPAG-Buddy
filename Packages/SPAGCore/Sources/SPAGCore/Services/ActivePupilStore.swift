import Foundation
import Observation

/// Where the app remembers which pupil is using it. The School app keeps this in the Keychain.
@MainActor
public protocol ActivePupilStore: AnyObject {
    var activePupilID: UUID? { get set }
}

/// The Home app's store. Home profiles have no login, so UserDefaults is enough.
@Observable
public final class UserDefaultsActivePupilStore: ActivePupilStore {
    private static let key = "activePupilID"
    @ObservationIgnored private let defaults: UserDefaults

    public var activePupilID: UUID? {
        didSet { defaults.set(activePupilID?.uuidString, forKey: Self.key) }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        activePupilID = defaults.string(forKey: Self.key).flatMap(UUID.init(uuidString:))
    }
}
