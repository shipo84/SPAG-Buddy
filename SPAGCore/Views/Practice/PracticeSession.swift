import Foundation
import Observation
import SwiftData

struct SessionResult: Identifiable {
    let id = UUID()
    var question: Question
    var result: MarkResult
}

struct SessionOutcome {
    var correct: Int
    var total: Int
    var starsEarned: Int
    var newBadges: [Badge]
}

@Observable
final class PracticeSession {
    enum Phase: Equatable {
        case answering
        case feedback(MarkResult)
        case finished
    }

    static let completionBonusStars = 2

    let id = UUID()
    let mode: SessionMode
    let questions: [Question]
    private(set) var index = 0
    private(set) var phase: Phase
    private(set) var results: [SessionResult] = []
    private(set) var outcome: SessionOutcome?
    var hintShown = false
    private var questionStartedAt = Date()

    init(mode: SessionMode, questions: [Question]) {
        self.mode = mode
        self.questions = questions
        phase = questions.isEmpty ? .finished : .answering
    }

    var current: Question? { questions.indices.contains(index) ? questions[index] : nil }
    var progress: Double { questions.isEmpty ? 1 : Double(index) / Double(questions.count) }
    var correctCount: Int { results.filter(\.result.correct).count }

    func submit(_ answer: PupilAnswer, pupil: PupilProfile, context: ModelContext, now: Date = .now) {
        guard let question = current, phase == .answering else { return }
        let result = AnswerMarker.mark(answer, for: question)
        let elapsed = Int(now.timeIntervalSince(questionStartedAt) * 1000)
        context.insert(Attempt(
            pupil: pupil,
            question: question,
            result: result,
            timeTakenMs: max(0, elapsed),
            hintUsed: hintShown,
            sessionId: id,
            mode: mode,
            answeredAt: now
        ))
        results.append(SessionResult(question: question, result: result))

        if mode.givesInstantFeedback {
            phase = .feedback(result)
        } else {
            advance(pupil: pupil, context: context)
        }
    }

    func advance(pupil: PupilProfile, context: ModelContext) {
        index += 1
        hintShown = false
        questionStartedAt = .now
        if index >= questions.count {
            finish(pupil: pupil, context: context)
        } else {
            phase = .answering
        }
    }

    private func finish(pupil: PupilProfile, context: ModelContext) {
        let correct = correctCount
        let stars = correct + Self.completionBonusStars
        pupil.stars += stars
        pupil.sessionsCompleted += 1
        if mode == .satsPractice { pupil.satsSessionsCompleted += 1 }
        pupil.streak = StreakCalculator.afterPractice(pupil.streak, now: .now)

        if let assignmentId = mode.assignmentId,
           let assignment = pupil.assignments.first(where: { $0.remoteId == assignmentId }) {
            assignment.completedAt = .now
        }

        let newBadges = Self.awardBadges(to: pupil, context: context)
        try? context.save()
        outcome = SessionOutcome(correct: correct, total: results.count, starsEarned: stars, newBadges: newBadges)
        phase = .finished
    }

    static func awardBadges(to pupil: PupilProfile, context: ModelContext) -> [Badge] {
        let records = pupil.attemptRecords
        let stats = ProgressCalculator.objectiveStats(from: records)
        var correctByStrand: [Strand: Int] = [:]
        for record in records where record.correct {
            correctByStrand[record.strand, default: 0] += 1
        }
        let input = BadgeInput(
            sessionsCompleted: pupil.sessionsCompleted,
            satsSessionsCompleted: pupil.satsSessionsCompleted,
            currentStreak: pupil.currentStreak,
            correctByStrand: correctByStrand,
            secureObjectives: stats.values.filter { $0.level == .secure }.count
        )
        let owned = Set(pupil.badges.map(\.badgeId))
        let fresh = BadgeRules.all.filter { BadgeRules.earned(input).contains($0.id) && !owned.contains($0.id) }
        for badge in fresh {
            context.insert(BadgeProgress(badgeId: badge.id, pupil: pupil))
        }
        return fresh
    }

    static func make(mode: SessionMode, pupil: PupilProfile, library: ContentLibrary) -> PracticeSession {
        let records = pupil.attemptRecords
        let recent = Set(records.sorted { $0.answeredAt > $1.answeredAt }.prefix(40).map(\.questionId))
        var rng = SystemRandomNumberGenerator()
        let questions = SessionBuilder(library: library).build(
            mode: mode,
            yearGroup: pupil.yearGroup,
            stats: ProgressCalculator.objectiveStats(from: records),
            recentQuestionIds: recent,
            using: &rng
        )
        return PracticeSession(mode: mode, questions: questions)
    }
}
