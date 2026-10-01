import Foundation
import SwiftData

@Model
public final class Attempt {
    /// Also used as `clientAttemptId` so retried uploads are not counted twice.
    @Attribute(.unique) public var id: UUID
    public var pupil: PupilProfile?
    public var questionId: String
    public var objectiveCode: String
    public var strandRaw: String
    public var yearGroup: Int
    public var correct: Bool
    public var answerGiven: String
    public var timeTakenMs: Int
    public var hintUsed: Bool
    public var sessionId: UUID
    public var sessionKind: String
    public var assignmentId: String?
    public var answeredAt: Date
    /// `true` until the server has accepted (or permanently rejected) the attempt.
    public var needsSync: Bool

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
        self.assignmentId = mode.assignmentId
        self.answeredAt = answeredAt
        self.needsSync = pupil.isInClass
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
