import Foundation

/// The privacy notice for pupils, written for children aged 5 to 11. Keep it in step with docs/privacy/pupil-privacy-notice.md.
public enum PrivacyNotice {
    public struct Section: Hashable, Identifiable, Sendable {
        public var symbol: String
        public var title: String
        public var body: String
        public var id: String { title }
    }

    /// `inClass` is nil before the child has chosen between joining a class and practising at home.
    public static func sections(inClass: Bool?) -> [Section] {
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
        switch inClass {
        case nil:
            sections.append(Section(
                symbol: "icloud.and.arrow.up",
                title: "Where it goes",
                body: "If you practise at home, your answers stay on this iPad. If you join a class, they are sent safely to your school so your teacher can help you. Other children cannot see them."
            ))
            sections.append(Section(
                symbol: "trash.fill",
                title: "Deleting it",
                body: "A grown-up can delete your profile from this iPad at any time. Your school deletes class answers after you leave, and always after two years."
            ))
        case true?:
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
        case false?:
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
            body: "Talk to your teacher or a grown-up you trust. You can always ask what SPAG Buddy knows about you."
        ))
        return sections
    }

    /// The whole notice as one piece of text for the read-aloud button.
    public static func spokenText(inClass: Bool?) -> String {
        sections(inClass: inClass).map { "\($0.title). \($0.body)" }.joined(separator: " ")
    }
}
