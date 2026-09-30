import Foundation

/// Plain copy of an attempt used by the progress, session and badge logic.
struct AttemptRecord: Hashable, Sendable {
    var questionId: String
    var objectiveCode: String
    var strand: Strand
    var correct: Bool
    var answeredAt: Date
}

/// Thresholds are shared with the teacher website (`web/lib/mastery.ts`) so pupils and teachers see the same picture.
enum MasteryLevel: String, CaseIterable, Sendable {
    case notStarted
    case needsSupport
    case developing
    case secure

    static let recentWindow = 10
    static let minimumAttemptsForSecure = 5
    static let secureAccuracy = 0.8
    static let supportAccuracy = 0.5

    var childLabel: String {
        switch self {
        case .notStarted: "Not tried yet"
        case .needsSupport: "Keep practising"
        case .developing: "Getting there"
        case .secure: "Super secure"
        }
    }
}

struct ObjectiveStats: Equatable, Sendable {
    var attempts = 0
    var correct = 0
    /// Most recent results last, capped to `MasteryLevel.recentWindow`.
    var recentResults: [Bool] = []
    var lastPractised: Date?

    var recentAccuracy: Double {
        recentResults.isEmpty ? 0 : Double(recentResults.filter { $0 }.count) / Double(recentResults.count)
    }

    var level: MasteryLevel {
        if attempts == 0 { return .notStarted }
        if attempts >= MasteryLevel.minimumAttemptsForSecure && recentAccuracy >= MasteryLevel.secureAccuracy {
            return .secure
        }
        return recentAccuracy < MasteryLevel.supportAccuracy && attempts >= 3 ? .needsSupport : .developing
    }
}

enum ProgressCalculator {
    static func objectiveStats(from attempts: [AttemptRecord]) -> [String: ObjectiveStats] {
        var stats: [String: ObjectiveStats] = [:]
        for attempt in attempts.sorted(by: { $0.answeredAt < $1.answeredAt }) {
            var entry = stats[attempt.objectiveCode, default: ObjectiveStats()]
            entry.attempts += 1
            if attempt.correct { entry.correct += 1 }
            entry.recentResults.append(attempt.correct)
            if entry.recentResults.count > MasteryLevel.recentWindow { entry.recentResults.removeFirst() }
            entry.lastPractised = attempt.answeredAt
            stats[attempt.objectiveCode] = entry
        }
        return stats
    }
}

enum StreakCalculator {
    struct Streak: Equatable, Sendable {
        var current: Int
        var longest: Int
        var lastPracticeDay: Date?
    }

    /// Updates a daily streak after practising on `now`. Practising twice on one day does not add to the streak.
    static func afterPractice(_ streak: Streak, now: Date, calendar: Calendar = .ukCalendar) -> Streak {
        let today = calendar.startOfDay(for: now)
        guard let last = streak.lastPracticeDay.map(calendar.startOfDay(for:)) else {
            return Streak(current: 1, longest: max(1, streak.longest), lastPracticeDay: today)
        }
        let days = calendar.dateComponents([.day], from: last, to: today).day ?? 0
        let current: Int
        switch days {
        case ..<1: current = max(streak.current, 1)
        case 1: current = streak.current + 1
        default: current = 1
        }
        return Streak(current: current, longest: max(streak.longest, current), lastPracticeDay: today)
    }

    /// The streak to show today: it resets to zero once a whole day has been missed.
    static func displayed(_ streak: Streak, now: Date, calendar: Calendar = .ukCalendar) -> Int {
        guard let last = streak.lastPracticeDay else { return 0 }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: calendar.startOfDay(for: now)).day ?? 0
        return days <= 1 ? streak.current : 0
    }
}

extension Calendar {
    static var ukCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_GB")
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .current
        return calendar
    }
}

struct Badge: Hashable, Identifiable, Sendable {
    var id: String
    var emoji: String
    var title: String
    var detail: String
}

struct BadgeInput: Sendable {
    var sessionsCompleted: Int
    var satsSessionsCompleted: Int
    var currentStreak: Int
    var correctByStrand: [Strand: Int]
    var secureObjectives: Int

    var totalCorrect: Int { correctByStrand.values.reduce(0, +) }
}

enum BadgeRules {
    static let all: [Badge] = [
        Badge(id: "first-steps", emoji: "🌱", title: "First steps", detail: "Finish your first practice."),
        Badge(id: "streak-3", emoji: "🔥", title: "On a roll", detail: "Practise 3 days in a row."),
        Badge(id: "streak-7", emoji: "🌟", title: "Super week", detail: "Practise 7 days in a row."),
        Badge(id: "correct-50", emoji: "🎯", title: "Sharp shooter", detail: "Get 50 answers right."),
        Badge(id: "correct-200", emoji: "🏆", title: "Champion", detail: "Get 200 answers right."),
        Badge(id: "spelling-25", emoji: "🐝", title: "Spelling bee", detail: "Spell 25 words correctly."),
        Badge(id: "punctuation-25", emoji: "✏️", title: "Punctuation pro", detail: "Get 25 punctuation answers right."),
        Badge(id: "grammar-25", emoji: "🧩", title: "Grammar ace", detail: "Get 25 grammar answers right."),
        Badge(id: "words-25", emoji: "📚", title: "Word explorer", detail: "Get 25 word answers right."),
        Badge(id: "secure-1", emoji: "🔒", title: "Locked in", detail: "Make a topic super secure."),
        Badge(id: "secure-5", emoji: "🧠", title: "Brain box", detail: "Make 5 topics super secure."),
        Badge(id: "sats-1", emoji: "📝", title: "Test ready", detail: "Finish a SATs practice paper."),
    ]

    static func badge(id: String) -> Badge? { all.first { $0.id == id } }

    static func earned(_ input: BadgeInput) -> Set<String> {
        var earned: Set<String> = []
        if input.sessionsCompleted >= 1 { earned.insert("first-steps") }
        if input.currentStreak >= 3 { earned.insert("streak-3") }
        if input.currentStreak >= 7 { earned.insert("streak-7") }
        if input.totalCorrect >= 50 { earned.insert("correct-50") }
        if input.totalCorrect >= 200 { earned.insert("correct-200") }
        if input.correctByStrand[.spelling, default: 0] >= 25 { earned.insert("spelling-25") }
        if input.correctByStrand[.punctuation, default: 0] >= 25 { earned.insert("punctuation-25") }
        if input.correctByStrand[.grammar, default: 0] >= 25 { earned.insert("grammar-25") }
        if input.correctByStrand[.vocabulary, default: 0] >= 25 { earned.insert("words-25") }
        if input.secureObjectives >= 1 { earned.insert("secure-1") }
        if input.secureObjectives >= 5 { earned.insert("secure-5") }
        if input.satsSessionsCompleted >= 1 { earned.insert("sats-1") }
        return earned
    }
}
