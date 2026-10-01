import Foundation
import Testing
@testable import SPAGSchoolSync

@MainActor
struct SwitchPupilTests {
    private let mia = UUID()
    private let sam = UUID()

    private func makeSession() -> (PupilSession, InMemorySecureStore) {
        let secure = InMemorySecureStore()
        let credentials = PupilCredentialStore(secureStore: secure, defaults: TestSupport.defaults())
        return (PupilSession(credentials: credentials, queue: AnswerQueue(directory: TestSupport.temporaryDirectory())), secure)
    }

    @Test func joiningSignsThePupilIn() throws {
        let (session, _) = makeSession()
        try session.signIn(pupilId: mia, deviceToken: "mia-token")
        #expect(session.credentials.activePupilID == mia)
        #expect(session.credentials.token(for: mia) == "mia-token")
    }

    @Test func switchingWithNothingUnsentNeedsNoWarning() throws {
        let (session, _) = makeSession()
        try session.signIn(pupilId: mia, deviceToken: "mia-token")
        #expect(session.unsentCount(for: mia) == 0)
    }

    @Test func unsentAnswersAreCountedForTheWarning() throws {
        let (session, _) = makeSession()
        try session.signIn(pupilId: mia, deviceToken: "mia-token")
        try session.queue.add(TestSupport.upload(), for: mia)
        try session.queue.add(TestSupport.upload(), for: mia)
        try session.queue.add(TestSupport.upload(), for: sam)
        #expect(session.unsentCount(for: mia) == 2)
    }

    @Test func switchPupilSignsOutAndDeletesTheTokenAndUnsentAnswers() throws {
        let (session, secure) = makeSession()
        try session.signIn(pupilId: mia, deviceToken: "mia-token")
        try session.queue.add(TestSupport.upload(), for: mia)

        session.switchPupil(mia)

        #expect(session.credentials.activePupilID == nil)
        #expect(session.credentials.token(for: mia) == nil)
        #expect(session.unsentCount(for: mia) == 0)
        #expect(!FileManager.default.fileExists(atPath: session.queue.folder(for: mia).path))
        #expect(secure.values.isEmpty)
    }

    @Test func switchPupilLeavesOtherPupilsAlone() throws {
        let (session, _) = makeSession()
        try session.signIn(pupilId: sam, deviceToken: "sam-token")
        try session.queue.add(TestSupport.upload(), for: sam)
        try session.signIn(pupilId: mia, deviceToken: "mia-token")

        session.switchPupil(mia)

        #expect(session.credentials.token(for: sam) == "sam-token")
        #expect(session.unsentCount(for: sam) == 1)
    }

    @Test func theNextPupilCanJoinAfterASwitch() throws {
        let (session, _) = makeSession()
        try session.signIn(pupilId: mia, deviceToken: "mia-token")
        session.switchPupil(mia)
        try session.signIn(pupilId: sam, deviceToken: "sam-token")

        #expect(session.credentials.activePupilID == sam)
        #expect(session.credentials.token(for: mia) == nil)
    }

    @Test func aRevokedCardSignsThePupilOutAndAsksForANewCard() throws {
        let (session, _) = makeSession()
        try session.signIn(pupilId: mia, deviceToken: "mia-token")
        try session.queue.add(TestSupport.upload(), for: mia)

        session.cardRevoked(mia)

        #expect(session.credentials.activePupilID == nil)
        #expect(session.credentials.token(for: mia) == nil)
        #expect(session.notice == .cardRevoked)
        #expect(session.notice?.message == "Ask your teacher for a new login card.")
        // Kept so they reach the teacher after the pupil joins with the new card.
        #expect(session.unsentCount(for: mia) == 1)
    }

    @Test func aRevokedCardForSomeoneElseDoesNotInterruptTheActivePupil() throws {
        let (session, _) = makeSession()
        try session.signIn(pupilId: sam, deviceToken: "sam-token")
        try session.signIn(pupilId: mia, deviceToken: "mia-token")

        session.cardRevoked(sam)

        #expect(session.credentials.activePupilID == mia)
        #expect(session.credentials.token(for: sam) == nil)
        #expect(session.notice == nil)
    }

    @Test func joiningAgainClearsTheRevokedMessage() throws {
        let (session, _) = makeSession()
        try session.signIn(pupilId: mia, deviceToken: "old-token")
        session.cardRevoked(mia)
        try session.signIn(pupilId: mia, deviceToken: "new-token")

        #expect(session.notice == nil)
        #expect(session.credentials.token(for: mia) == "new-token")
    }

    /// The server's reply when a device token has been revoked, the pupil deleted or the class archived.
    @Test func theServersNoLongerLinkedReplyCountsAsARevokedCard() async throws {
        let (session, _) = makeSession()
        try session.queue.add(TestSupport.upload(), for: mia)
        let body = try JSONDecoder.api.decode(APIErrorBody.self, from: Data(#"{"error":"unauthorised","message":"This device is no longer linked to a class"}"#.utf8))
        let server = FakeAttemptServer()
        server.respond = { _ in throw APIError.from(status: 401, body: body)! }

        let report = await AnswerSender(api: server, queue: session.queue).send(for: mia, token: "mia-token")

        #expect(report.outcome == .cardRevoked)
    }
}
