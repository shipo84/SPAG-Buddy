import Foundation

/// Rules for the child profiles a parent sets up in SPAG Buddy Home. There are no accounts, class codes or PINs.
enum HomeFamily {
    static let maxChildren = 4
    static let maxNameLength = 20

    enum NameProblem: Equatable {
        case empty
        case alreadyUsed
    }

    static func canAddChild(existingCount: Int) -> Bool {
        existingCount < maxChildren
    }

    static func cleanedName(_ raw: String) -> String {
        String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxNameLength))
    }

    /// Two children with the same name would look the same on the "Who is practising?" screen.
    static func nameProblem(_ raw: String, existingNames: [String]) -> NameProblem? {
        let name = cleanedName(raw)
        if name.isEmpty { return .empty }
        if existingNames.contains(where: { $0.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }) {
            return .alreadyUsed
        }
        return nil
    }
}

/// Web pages the grown-ups area opens in Safari. They sit behind the grown-ups gate, as the Kids Category requires.
enum HomeLinks {
    static let privacyPolicy = URL(string: "https://digitalclubhouse.org/spag-buddy/home/privacy/")!
    static let spagBuddySchool = URL(string: "https://digitalclubhouse.org/spag-buddy/school/")!
}

/// One child's progress in one strand, for the grown-ups progress summary.
struct TopicSummary: Identifiable, Equatable {
    struct Skill: Identifiable, Equatable {
        var objective: Objective
        var stats: ObjectiveStats
        var id: String { objective.code }
    }

    var strand: Strand
    var skills: [Skill]

    var id: Strand { strand }
    var answered: Int { skills.map(\.stats.attempts).reduce(0, +) }
    var correct: Int { skills.map(\.stats.correct).reduce(0, +) }

    func count(_ level: MasteryLevel) -> Int {
        skills.filter { $0.stats.level == level }.count
    }
}

enum HomeProgressSummary {
    /// Skills for the child's year and the year below (as on the child's own progress screen), plus anything else
    /// they have practised, for example before a grown-up changed their year.
    static func topics(objectives: [Objective], attempts: [AttemptRecord], yearGroup: Int) -> [TopicSummary] {
        let stats = ProgressCalculator.objectiveStats(from: attempts)
        let years = max(1, yearGroup - 1)...max(1, yearGroup)
        let shown = objectives
            .filter { years.contains($0.yearGroup) || stats[$0.code] != nil }
            .sorted { ($0.yearGroup, $0.code) < ($1.yearGroup, $1.code) }

        return Strand.allCases.compactMap { strand in
            let skills = shown
                .filter { $0.strand == strand }
                .map { TopicSummary.Skill(objective: $0, stats: stats[$0.code] ?? ObjectiveStats()) }
            return skills.isEmpty ? nil : TopicSummary(strand: strand, skills: skills)
        }
    }
}

/// "Where is my child's data?" for parents. Keep it in step with the Home privacy policy at `HomeLinks.privacyPolicy`.
enum HomeDataNotice {
    struct Section: Hashable, Identifiable {
        var symbol: String
        var title: String
        var body: String
        var id: String { title }
    }

    static let headline = "Everything stays on this iPad. Nothing is sent to us or anyone else."

    static let sections: [Section] = [
        Section(
            symbol: "person.text.rectangle",
            title: "What SPAG Buddy keeps",
            body: "For each child: the first name or nickname you typed, their picture and their school year. It also keeps the questions they answer, what they typed or tapped, whether it was right, and their stars, stickers and streak."
        ),
        Section(
            symbol: "hand.raised.fill",
            title: "What it never asks for",
            body: "No accounts, email addresses or passwords. No surnames, birthdays, photos or location. There are no adverts, no tracking and no analytics."
        ),
        Section(
            symbol: "ipad",
            title: "Where it is kept",
            body: "Only in SPAG Buddy on this iPad. The app does not send your child's answers or details over the internet, so we cannot see them. Other apps cannot see them either."
        ),
        Section(
            symbol: "eye.fill",
            title: "Who can see it",
            body: "Anyone who uses SPAG Buddy on this iPad can see the children's progress. Deleting and changing profiles is behind the grown-ups question."
        ),
        Section(
            symbol: "externaldrive.fill",
            title: "Backups",
            body: "If you back up this iPad to iCloud or a computer, SPAG Buddy is included in your backup, like your other apps. We cannot see your backups."
        ),
        Section(
            symbol: "trash.fill",
            title: "Deleting it",
            body: "In Grown-ups you can delete one child's progress, remove a child, or delete everything. Deleting the app from this iPad also deletes everything."
        ),
        Section(
            symbol: "building.columns.fill",
            title: "SPAG Buddy School",
            body: "Home progress cannot be moved to SPAG Buddy School. Home never sends anything off this iPad, so there is no copy anywhere else to move."
        ),
    ]
}
