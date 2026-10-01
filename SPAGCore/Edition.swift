import Foundation

/// The two App Store apps built from this code. Each app target sets `Edition.current` in its own folder.
enum Edition: Sendable {
    /// SPAG Buddy Home: strictly on-device. It never connects to a server.
    case home
    /// SPAG Buddy School: pupils join a class and their answers are sent to the teacher dashboard.
    case school
}
