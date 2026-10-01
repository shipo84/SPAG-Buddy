import Foundation
import SwiftUI

/// Which App Store app is running. Each app target injects its edition into the SwiftUI
/// environment at launch; shared views read it with `@Environment(\.edition)`.
public enum Edition: String, CaseIterable, Sendable {
    /// SPAG Buddy Home, for parents. Everything stays on the device.
    case home
    /// SPAG Buddy School, for classes. Answers sync to the teacher dashboard.
    case school

    /// The SwiftData store file in Application Support. Each edition has its own,
    /// so the two apps never share or migrate data.
    public var storeFileName: String {
        switch self {
        case .home: "SPAGHome.store"
        case .school: "SPAGSchool.store"
        }
    }

    /// The store an earlier single-edition build used. Home keeps the existing App Store listing,
    /// so its pupils' progress is moved across once; School is a new app with nothing to move.
    var legacyStoreFileName: String? {
        switch self {
        case .home: "default.store"
        case .school: nil
        }
    }
}

private struct EditionKey: EnvironmentKey {
    static let defaultValue = Edition.home
}

extension EnvironmentValues {
    public var edition: Edition {
        get { self[EditionKey.self] }
        set { self[EditionKey.self] = newValue }
    }
}
