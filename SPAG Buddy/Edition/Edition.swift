import Foundation
import SwiftUI

/// Which of the two SPAG Buddy apps this build is.
///
/// Home and School are built from the same code but are separate apps with separate data.
/// Nothing here is a per-pupil choice: the edition is fixed for the whole app at build time.
/// See docs/two-editions-audit.md.
enum Edition: String, CaseIterable, Identifiable, Sendable {
    /// For families. Strictly on-device: no class, no sync, no teacher.
    case home
    /// For classes. Pupils join with a login card and answers sync to the teacher dashboard.
    case school

    var id: String { rawValue }

    var isSchool: Bool { self == .school }

    /// The name shown on the home screen and at the top of the app.
    var displayName: String {
        switch self {
        case .home: "SPAG Buddy Home"
        case .school: "SPAG Buddy School"
        }
    }

    /// The short label used on the edition badge.
    var shortName: String {
        switch self {
        case .home: "Home"
        case .school: "School"
        }
    }

    var symbolName: String {
        switch self {
        case .home: "house.fill"
        case .school: "graduationcap.fill"
        }
    }

    /// The second line on the welcome screen.
    var tagline: String {
        switch self {
        case .home: "Practise spelling, punctuation and grammar at home. Everything stays on this iPad."
        case .school: "Practise spelling, punctuation and grammar with your class."
        }
    }

    /// Read from `SPAGBuddyEdition` in Info.plist, which comes from the `SPAG_EDITION` build setting.
    /// Anything unrecognised is treated as Home, because Home is the edition that can never send data anywhere.
    /// In debug builds the launch argument `-SPAGEdition home` or `-SPAGEdition school` overrides it,
    /// so both editions can be tried from one scheme (Edit Scheme > Run > Arguments).
    static let current: Edition = {
        #if DEBUG
        if let override = UserDefaults.standard.string(forKey: "SPAGEdition"),
           let edition = Edition(rawValue: override.lowercased()) {
            return edition
        }
        #endif
        let configured = Bundle.main.object(forInfoDictionaryKey: "SPAGBuddyEdition") as? String ?? ""
        return Edition(rawValue: configured.lowercased()) ?? .home
    }()
}

/// Small capsule that says which edition this is. Shown on the welcome screen and the home screen.
struct EditionBadge: View {
    var edition: Edition
    @Environment(\.appTheme) private var theme

    var body: some View {
        Label(edition.shortName, systemImage: edition.symbolName)
            .pupilText(.caption, weight: .bold)
            .foregroundStyle(theme.onPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(theme.primary, in: Capsule())
            .accessibilityLabel("\(edition.displayName) edition")
    }
}
