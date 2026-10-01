import Foundation

/// The privacy notice for pupils, written for children aged 5 to 11. Keep it in step with docs/privacy/pupil-privacy-notice.md.
///
/// SPAG Buddy Home never sends anything anywhere, so this notice must never mention a school,
/// a class or a teacher seeing answers.
enum PrivacyNotice {
    struct Section: Hashable, Identifiable, Sendable {
        var symbol: String
        var title: String
        var body: String
        var id: String { title }
    }

    static let sections: [Section] = [
        Section(
            symbol: "person.fill",
            title: "What SPAG Buddy knows about you",
            body: "Your first name, your animal picture and your year group. It does not know your surname, where you live, your birthday or what you look like."
        ),
        Section(
            symbol: "pencil.and.list.clipboard",
            title: "What it remembers",
            body: "The questions you answer, what you typed or tapped, and whether it was right. This helps Buddy choose the best questions for you."
        ),
        Section(
            symbol: "ipad",
            title: "Where it goes",
            body: "Nowhere! Your answers stay on this iPad. Nobody else can see them."
        ),
        Section(
            symbol: "trash.fill",
            title: "Deleting it",
            body: "A grown-up can delete your profile in the grown-ups' settings. Then everything is gone from this iPad."
        ),
        Section(
            symbol: "questionmark.bubble.fill",
            title: "Worried about something?",
            body: "Talk to a grown-up you trust. You can always ask what SPAG Buddy knows about you."
        ),
    ]

    /// The whole notice as one piece of text for the read-aloud button.
    static var spokenText: String {
        sections.map { "\($0.title). \($0.body)" }.joined(separator: " ")
    }
}
