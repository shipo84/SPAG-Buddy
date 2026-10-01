import Foundation
import Testing
@testable import SPAGCore

@MainActor
struct ProgressTests {
    private let calendar = Calendar.ukCalendar

    private func day(_ offset: Int, hour: Int = 10) -> Date {
        let base = calendar.date(from: DateComponents(year: 2026, month: 9, day: 1, hour: hour))!
        return calendar.date(byAdding: .day, value: offset, to: base)!
    }

    private func attempts(_ results: [Bool], objective: String = "Y4-G-pronouns") -> [AttemptRecord] {
        results.enumerated().map { index, correct in
            AttemptRecord(questionId: "q\(index)", objectiveCode: objective, strand: .grammar, correct: correct, answeredAt: day(0).addingTimeInterval(Double(index)))
        }
    }

    @Test func masteryLevels() {
        #expect(ObjectiveStats().level == .notStarted)
        #expect(ProgressCalculator.objectiveStats(from: attempts([true, true]))["Y4-G-pronouns"]?.level == .developing)
        #expect(ProgressCalculator.objectiveStats(from: attempts([false, false, false]))["Y4-G-pronouns"]?.level == .needsSupport)
        #expect(ProgressCalculator.objectiveStats(from: attempts([true, true, true, true, true]))["Y4-G-pronouns"]?.level == .secure)
    }

    @Test func masteryUsesOnlyRecentAttempts() {
        let history = Array(repeating: false, count: 20) + Array(repeating: true, count: 10)
        let stats = ProgressCalculator.objectiveStats(from: attempts(history))["Y4-G-pronouns"]
        #expect(stats?.attempts == 30)
        #expect(stats?.recentResults.count == MasteryLevel.recentWindow)
        #expect(stats?.level == .secure)
    }

    @Test func streakGrowsOnConsecutiveDays() {
        var streak = StreakCalculator.Streak(current: 0, longest: 0, lastPracticeDay: nil)
        streak = StreakCalculator.afterPractice(streak, now: day(0))
        streak = StreakCalculator.afterPractice(streak, now: day(0, hour: 18))
        #expect(streak.current == 1)
        streak = StreakCalculator.afterPractice(streak, now: day(1))
        streak = StreakCalculator.afterPractice(streak, now: day(2))
        #expect(streak.current == 3)
        #expect(streak.longest == 3)
    }

    @Test func streakResetsAfterAMissedDay() {
        var streak = StreakCalculator.Streak(current: 4, longest: 4, lastPracticeDay: day(0))
        #expect(StreakCalculator.displayed(streak, now: day(1)) == 4)
        #expect(StreakCalculator.displayed(streak, now: day(2)) == 0)
        streak = StreakCalculator.afterPractice(streak, now: day(3))
        #expect(streak.current == 1)
        #expect(streak.longest == 4)
    }

    @Test func badges() {
        let none = BadgeRules.earned(BadgeInput(sessionsCompleted: 0, satsSessionsCompleted: 0, currentStreak: 0, correctByStrand: [:], secureObjectives: 0))
        #expect(none.isEmpty)

        let some = BadgeRules.earned(BadgeInput(
            sessionsCompleted: 5,
            satsSessionsCompleted: 1,
            currentStreak: 3,
            correctByStrand: [.spelling: 30, .grammar: 25],
            secureObjectives: 1
        ))
        #expect(some == ["first-steps", "streak-3", "correct-50", "spelling-25", "grammar-25", "secure-1", "sats-1"])
        #expect(some.allSatisfy { BadgeRules.badge(id: $0) != nil })
    }
}
