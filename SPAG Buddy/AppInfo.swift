import Foundation

/// This project is the Home edition of SPAG Buddy: for families, strictly on-device.
///
/// SPAG Buddy School (for classes, with login cards and a teacher dashboard) is a separate app
/// in a separate Xcode project with its own bundle ID. The two apps share no data.
/// See docs/two-editions-audit.md.
enum AppInfo {
    static let name = "SPAG Buddy Home"
    static let tagline = "Practise spelling, punctuation and grammar at home. Everything stays on this iPad."
}
