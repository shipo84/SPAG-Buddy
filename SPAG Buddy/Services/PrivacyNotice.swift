import Foundation

/// The privacy notice for pupils, written for children aged 5 to 11. Keep it in step with docs/privacy/pupil-privacy-notice.md.
enum PrivacyNotice {
    struct Section: Hashable, Identifiable, Sendable {
        var symbol: String
        var title: String
        var body: String
        var id: String { title }
    }

    /// Each edition has its own wording. Home never mentions a school or a teacher seeing answers,
    /// because in Home nothing ever leaves the iPad.
    static func sections(for edition: Edition) -> [Section] {
        var sections = [
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
        ]
        switch edition {
        case .school:
            sections.append(Section(
                symbol: "person.2.fill",
                title: "Who can see it",
                body: "Your teacher can see your answers so they can help you learn. Other children cannot see your answers or your stars."
            ))
            sections.append(Section(
                symbol: "icloud.and.arrow.up",
                title: "Where it goes",
                body: "Your answers are sent safely to your school's SPAG Buddy account when the iPad is online. They are never sold or used for adverts."
            ))
            sections.append(Section(
                symbol: "trash.fill",
                title: "Deleting it",
                body: "Your school deletes your answers after you leave the class, and always after two years. You or a grown-up at home can ask your teacher to delete them sooner."
            ))
        case .home:
            sections.append(Section(
                symbol: "ipad",
                title: "Where it goes",
                body: "Nowhere! Your answers stay on this iPad. Nobody else can see them."
            ))
            sections.append(Section(
                symbol: "trash.fill",
                title: "Deleting it",
                body: "A grown-up can delete your profile in the grown-ups' settings. Then everything is gone from this iPad."
            ))
        }
        sections.append(Section(
            symbol: "questionmark.bubble.fill",
            title: "Worried about something?",
            body: edition.isSchool
                ? "Talk to your teacher or a grown-up you trust. You can always ask what SPAG Buddy knows about you."
                : "Talk to a grown-up you trust. You can always ask what SPAG Buddy knows about you."
        ))
        return sections
    }

    /// The whole notice as one piece of text for the read-aloud button.
    static func spokenText(for edition: Edition) -> String {
        sections(for: edition).map { "\($0.title). \($0.body)" }.joined(separator: " ")
    }
}
