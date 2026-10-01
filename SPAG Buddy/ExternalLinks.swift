import Foundation

/// Web pages a grown-up can open in Safari from the grown-ups' settings.
enum ExternalLinks {
    // TODO: Replace with SPAG Buddy School's App Store ID and the school privacy notice address before release.
    static let appStoreReview = URL(string: "https://apps.apple.com/app/id0000000000?action=write-review")!
    static let privacyPolicy = URL(string: "https://www.example.com/spag-buddy-school/privacy")!
}
