import Foundation
import SwiftData

@Model
final class Attempt {
    @Attribute(.unique) var id: UUID
    var pupil: PupilProfile?
    var questionId: String
    var objectiveCode: String
    var strandRaw: String
    var yearGroup: Int
    var correct: Bool
    var answerGiven: String
    var timeTakenMs: Int
    var hintUsed: Bool
    var sessionId: UUID
    var sessionKind: String
    var answeredAt: Date

    init(
        pupil: PupilProfile,
        question: Question,
        result: MarkResult,
        timeTakenMs: Int,
        hintUsed: Bool,
        sessionId: UUID,
        mode: SessionMode,
        answeredAt: Date = .now
    ) {
        self.id = UUID()
        self.pupil = pupil
        self.questionId = question.id
        self.objectiveCode = question.objectiveCode
        self.strandRaw = question.strand.rawValue
        self.yearGroup = question.yearGroup
        self.correct = result.correct
        self.answerGiven = result.answerGiven
        self.timeTakenMs = timeTakenMs
        self.hintUsed = hintUsed
        self.sessionId = sessionId
        self.sessionKind = mode.kind
        self.answeredAt = answeredAt
    }

    var strand: Strand { Strand(rawValue: strandRaw) ?? .grammar }

    var record: AttemptRecord {
        AttemptRecord(
            questionId: questionId,
            objectiveCode: objectiveCode,
            strand: strand,
            correct: correct,
            answeredAt: answeredAt
        )
    }
}
