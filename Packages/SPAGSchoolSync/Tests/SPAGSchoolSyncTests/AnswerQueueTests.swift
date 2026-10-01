import Foundation
import Testing
@testable import SPAGSchoolSync

@MainActor
struct AnswerQueueTests {
    private let pupil = UUID()
    private let directory = TestSupport.temporaryDirectory()

    private func makeQueue() -> AnswerQueue { AnswerQueue(directory: directory) }

    @Test func answersAreKeptUntilTheyAreSent() throws {
        let queue = makeQueue()
        let answers = (0..<3).map { TestSupport.upload(answeredAt: Double($0)) }
        for answer in answers { try queue.add(answer, for: pupil) }

        let relaunched = makeQueue()
        #expect(relaunched.count(for: pupil) == 3)
        #expect(relaunched.pending(for: pupil) == answers)
    }

    @Test func filesAreProtectedUntilFirstUnlock() throws {
        #expect(AnswerQueue.writingOptions.contains(.completeFileProtectionUntilFirstUserAuthentication))
        #expect(AnswerQueue.writingOptions.contains(.atomic))
        #expect(AnswerQueue.protection == .completeUntilFirstUserAuthentication)

        let queue = makeQueue()
        try queue.add(TestSupport.upload(), for: pupil)
        #if os(iOS) && !targetEnvironment(simulator)
        let attributes = try FileManager.default.attributesOfItem(atPath: queue.folder(for: pupil).path)
        #expect(attributes[.protectionKey] as? FileProtectionType == .completeUntilFirstUserAuthentication)
        #endif
    }

    @Test func addingTheSameAnswerTwiceKeepsOneCopy() throws {
        let queue = makeQueue()
        let answer = TestSupport.upload()
        try queue.add(answer, for: pupil)
        try queue.add(answer, for: pupil)
        #expect(queue.count(for: pupil) == 1)
        #expect(queue.contains(answer.clientAttemptId, for: pupil))
    }

    @Test func eachPupilHasTheirOwnQueue() throws {
        let queue = makeQueue()
        let other = UUID()
        try queue.add(TestSupport.upload(), for: pupil)
        try queue.add(TestSupport.upload(), for: other)
        try queue.add(TestSupport.upload(), for: other)

        queue.removeAll(for: pupil)

        #expect(queue.count(for: pupil) == 0)
        #expect(queue.count(for: other) == 2)
    }

    @Test func sendsOldestFirstInBatchesAndDeletesConfirmedAnswers() async throws {
        let queue = makeQueue()
        let answers = (0..<250).map { TestSupport.upload(answeredAt: Double($0)) }
        for answer in answers.reversed() { try queue.add(answer, for: pupil) }
        let server = FakeAttemptServer()

        let report = await AnswerSender(api: server, queue: queue).send(for: pupil, token: "device-token")

        #expect(server.received.map(\.count) == [100, 100, 50])
        #expect(server.receivedIds == answers.map(\.clientAttemptId))
        #expect(server.tokens == ["device-token", "device-token", "device-token"])
        #expect(report == .init(sent: Set(answers.map(\.clientAttemptId)), outcome: .finished))
        #expect(queue.count(for: pupil) == 0)
    }

    @Test func answersTheServerDidNotConfirmStayQueued() async throws {
        let queue = makeQueue()
        let kept = TestSupport.upload(answeredAt: 1)
        let accepted = TestSupport.upload(answeredAt: 2)
        let rejected = TestSupport.upload(answeredAt: 3)
        for answer in [kept, accepted, rejected] { try queue.add(answer, for: pupil) }
        let server = FakeAttemptServer()
        server.respond = { _ in
            AttemptUploadResponse(
                accepted: [accepted.clientAttemptId],
                rejected: [.init(clientAttemptId: rejected.clientAttemptId, reason: "unknown_question")]
            )
        }

        let report = await AnswerSender(api: server, queue: queue).send(for: pupil, token: "t")

        #expect(report.sent == [accepted.clientAttemptId, rejected.clientAttemptId])
        #expect(queue.pending(for: pupil) == [kept])
    }

    @Test func idsTheServerInventsAreIgnored() async throws {
        let queue = makeQueue()
        let answer = TestSupport.upload()
        try queue.add(answer, for: pupil)
        let server = FakeAttemptServer()
        server.respond = { _ in AttemptUploadResponse(accepted: [UUID()], rejected: []) }

        let report = await AnswerSender(api: server, queue: queue).send(for: pupil, token: "t")

        #expect(report.sent.isEmpty)
        #expect(queue.pending(for: pupil) == [answer])
    }

    /// A resend after a failure carries the same client ids, so the server can ignore duplicates.
    @Test func resendingAfterAFailureReusesTheSameClientIds() async throws {
        let queue = makeQueue()
        let answers = (0..<150).map { TestSupport.upload(answeredAt: Double($0)) }
        for answer in answers { try queue.add(answer, for: pupil) }
        let server = FakeAttemptServer()
        var calls = 0
        server.respond = { batch in
            calls += 1
            if calls == 2 { throw APIError.transport }
            return AttemptUploadResponse(accepted: batch.map(\.clientAttemptId), rejected: [])
        }

        let first = await AnswerSender(api: server, queue: queue).send(for: pupil, token: "t")
        #expect(first.outcome == .failed)
        #expect(first.sent == Set(answers.prefix(100).map(\.clientAttemptId)))
        #expect(queue.pending(for: pupil) == Array(answers.suffix(50)))

        let second = await AnswerSender(api: server, queue: queue).send(for: pupil, token: "t")
        #expect(second.outcome == .finished)
        #expect(server.received.last?.map(\.clientAttemptId) == answers.suffix(50).map(\.clientAttemptId))
        #expect(server.received[1] == server.received[2])
        #expect(queue.count(for: pupil) == 0)
    }

    @Test func aRevokedCardStopsSendingAndKeepsTheAnswers() async throws {
        let queue = makeQueue()
        let answer = TestSupport.upload()
        try queue.add(answer, for: pupil)
        let server = FakeAttemptServer()
        server.respond = { _ in throw APIError.unauthorised }

        let report = await AnswerSender(api: server, queue: queue).send(for: pupil, token: "t")

        #expect(report == .init(sent: [], outcome: .cardRevoked))
        #expect(queue.pending(for: pupil) == [answer])
    }

    @Test func anEmptyQueueSendsNothing() async {
        let server = FakeAttemptServer()
        let report = await AnswerSender(api: server, queue: makeQueue()).send(for: pupil, token: "t")
        #expect(report == .init(sent: [], outcome: .finished))
        #expect(server.received.isEmpty)
    }

    @Test func queuedAnswersUseTheServersJSONShape() throws {
        let queue = makeQueue()
        try queue.add(TestSupport.upload(), for: pupil)
        let file = try #require(FileManager.default.contentsOfDirectory(at: queue.folder(for: pupil), includingPropertiesForKeys: nil).first)
        let object = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        #expect(Set(object.keys) == ["clientAttemptId", "questionId", "correct", "answerGiven", "timeTakenMs", "hintUsed", "sessionId", "sessionKind", "answeredAt"])
    }
}
