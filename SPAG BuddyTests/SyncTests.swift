import Foundation
import Testing
@testable import SPAG_Buddy

@MainActor
struct SyncTests {
    private func upload(_ seconds: TimeInterval) -> AttemptUpload {
        AttemptUpload(
            clientAttemptId: UUID(),
            questionId: "y4-fa-01",
            correct: true,
            answerGiven: "Before breakfast, Sam fed the cat.",
            timeTakenMs: 4000,
            hintUsed: false,
            sessionId: UUID(),
            sessionKind: "daily",
            assignmentId: nil,
            answeredAt: Date(timeIntervalSince1970: 1_790_000_000 + seconds)
        )
    }

    @Test func batchesAreOldestFirstAndCapped() {
        let uploads = (0..<250).reversed().map { upload(Double($0)) }
        let batches = SyncPlanner.batches(uploads)
        #expect(batches.map(\.count) == [100, 100, 50])
        #expect(batches[0].first?.answeredAt == Date(timeIntervalSince1970: 1_790_000_000))
        #expect(SyncPlanner.batches([]).isEmpty)
    }

    @Test func retryBacksOffUpToFifteenMinutes() {
        #expect(SyncPlanner.retryDelay(afterFailures: 0) == 0)
        #expect(SyncPlanner.retryDelay(afterFailures: 1) == 10)
        #expect(SyncPlanner.retryDelay(afterFailures: 3) == 40)
        #expect(SyncPlanner.retryDelay(afterFailures: 20) == 900)
    }

    @Test func acceptedAndPermanentlyRejectedAttemptsAreSettled() throws {
        let a = UUID()
        let b = UUID()
        let json = #"{"accepted":["\#(a.uuidString)"],"rejected":[{"clientAttemptId":"\#(b.uuidString)","reason":"unknown_question"}]}"#
        let response = try JSONDecoder.api.decode(AttemptUploadResponse.self, from: Data(json.utf8))
        #expect(response.settledIds == [a, b])
    }

    @Test func uploadsEncodeInTheShapeTheServerExpects() throws {
        let data = try JSONEncoder.api.encode(AttemptBatch(attempts: [upload(0)]))
        let object = try JSONSerialization.jsonObject(with: data) as? [String: [[String: Any]]]
        let item = try #require(object?["attempts"]?.first)
        #expect(Set(item.keys) == ["clientAttemptId", "questionId", "correct", "answerGiven", "timeTakenMs", "hintUsed", "sessionId", "sessionKind", "answeredAt"])
        #expect((item["answeredAt"] as? String)?.hasSuffix("Z") == true)
    }

    @Test func assignmentDueDatesAreUKDays() throws {
        let json = #"{"assignments":[{"id":"a1","title":"Commas","objectiveCodes":["Y4-P-comma-after-fronted-adverbial"],"spellingListId":null,"dueDate":"2026-10-09"}]}"#
        let response = try JSONDecoder.api.decode(AssignmentsResponse.self, from: Data(json.utf8))
        let due = try #require(response.assignments.first?.dueDateValue)
        let parts = Calendar.ukCalendar.dateComponents([.year, .month, .day, .hour], from: due)
        #expect(parts.year == 2026 && parts.month == 10 && parts.day == 9 && parts.hour == 0)
    }

    @Test func httpStatusesMapToFriendlyErrors() {
        #expect(APIError.from(status: 200, body: nil) == nil)
        #expect(APIError.from(status: 401, body: nil) == .unauthorised)
        #expect(APIError.from(status: 404, body: nil) == .notFound)
        #expect(APIError.from(status: 429, body: nil) == .tooManyAttempts)
        #expect(APIError.from(status: 400, body: APIErrorBody(error: "bad_request", message: "pin must be 4 digits")) == .badRequest("pin must be 4 digits"))
        #expect(APIError.from(status: 503, body: nil) == .server(503))
    }

    @Test func contentVersionsCompareNumerically() {
        #expect(ContentVersion.isNewer("2026.10.1", than: "2026.09.1"))
        #expect(ContentVersion.isNewer("2026.09.10", than: "2026.09.9"))
        #expect(!ContentVersion.isNewer("2026.09.1", than: "2026.09.1"))
        #expect(!ContentVersion.isNewer("2026.08.5", than: "2026.09.1"))
        #expect(ContentVersion.isNewer("2026.09.1.1", than: "2026.09.1"))
    }

    @Test func contentLoadsFromADownloadedFolder() throws {
        let library = try ContentLibrary.load(from: TestContent.directory)
        #expect(library.manifest.contentVersion == TestContent.library.manifest.contentVersion)
    }
}
