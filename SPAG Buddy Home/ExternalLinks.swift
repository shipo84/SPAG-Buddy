import Foundation

/// The only web addresses allowed in SPAG Buddy Home, and the allow-list for `Scripts/check-home-on-device.sh`.
///
/// Both are opened with SwiftUI `Link`, which hands them to Safari. The app itself never connects to them.
/// The script accepts at most two links, each written on one line exactly like the two below.
enum ExternalLinks {
    // TODO: Replace with SPAG Buddy Home's App Store ID and the published privacy policy address before release.
    static let appStoreReview = URL(string: "https://apps.apple.com/app/id0000000000?action=write-review")!
    static let privacyPolicy = URL(string: "https://www.example.com/spag-buddy-home/privacy")!
}
