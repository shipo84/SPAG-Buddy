import Foundation
import Testing
@testable import SPAG_Buddy

@MainActor
struct SessionBuilderTests {
    let builder = SessionBuilder(library: TestContent.library)

    @Test func dailySessionHasRequestedLengthAndNoRepeats() {
        var rng = SeededGenerator(seed: 1)
        let questions = builder.build(mode: .daily, yearGroup: 4, stats: [:], using: &rng)
        #expect(questions.count == SessionMode.daily.defaultLength)
        #expect(Set(questions.map(\.id)).count == questions.count)
        #expect(questions.allSatisfy { (3...4).contains($0.yearGroup) })
    }

    @Test func dailySessionMixesObjectivesInsteadOfOnlySpelling() {
        var rng = SeededGenerator(seed: 7)
        let questions = builder.build(mode: .daily, yearGroup: 4, stats: [:], using: &rng)
        #expect(Set(questions.map(\.objectiveCode)).count >= 3)
    }

    @Test func weakObjectivesAppearMoreOften() {
        let weak = "Y4-P-direct-speech"
        let secure = "Y4-G-standard-english"
        var stats: [String: ObjectiveStats] = [:]
        stats[weak] = ObjectiveStats(attempts: 10, correct: 2, recentResults: Array(repeating: false, count: 8) + [true, true])
        stats[secure] = ObjectiveStats(attempts: 10, correct: 10, recentResults: Array(repeating: true, count: 10))

        var weakCount = 0
        var secureCount = 0
        for seed in 1...200 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let questions = builder.build(mode: .strand(.punctuation), yearGroup: 4, stats: stats, using: &rng)
                + builder.build(mode: .strand(.grammar), yearGroup: 4, stats: stats, using: &rng)
            weakCount += questions.filter { $0.objectiveCode == weak }.count
            secureCount += questions.filter { $0.objectiveCode == secure }.count
        }
        #expect(weakCount > secureCount)
    }

    @Test func recentlySeenQuestionsAreAvoidedWhenPossible() {
        let objective = "Y4-S-homophones"
        let all = TestContent.library.questions.filter { $0.objectiveCode == objective }
        let recent = Set(all.prefix(all.count - 2).map(\.id))
        var rng = SeededGenerator(seed: 3)
        let questions = builder.build(mode: .objective(objective), yearGroup: 4, stats: [:], recentQuestionIds: recent, length: 2, using: &rng)
        #expect(questions.allSatisfy { !recent.contains($0.id) })
    }

    @Test func strandSessionOnlyUsesThatStrand() {
        var rng = SeededGenerator(seed: 4)
        let questions = builder.build(mode: .strand(.punctuation), yearGroup: 4, stats: [:], using: &rng)
        #expect(!questions.isEmpty)
        #expect(questions.allSatisfy { $0.strand == .punctuation })
    }

    @Test func spellingListSessionUsesOnlyThatList() {
        var rng = SeededGenerator(seed: 5)
        let questions = builder.build(mode: .spellingList("y34-statutory"), yearGroup: 4, stats: [:], using: &rng)
        #expect(questions.count == 10)
        #expect(questions.allSatisfy { $0.id.hasPrefix("spell-y34-statutory-") })
    }

    @Test func assignmentCombinesObjectivesAndSpellingList() {
        var rng = SeededGenerator(seed: 6)
        let mode = SessionMode.assignment(id: "a1", objectiveCodes: ["Y4-G-fronted-adverbials"], spellingListId: "y34-statutory")
        let questions = builder.build(mode: mode, yearGroup: 4, stats: [:], using: &rng)
        #expect(questions.contains { $0.objectiveCode == "Y4-G-fronted-adverbials" })
        #expect(questions.contains { $0.type == .spelling })
        #expect(mode.assignmentId == "a1")
    }

    @Test func satsPracticeOnlyUsesSatsStyleQuestionsAndHidesFeedback() {
        var rng = SeededGenerator(seed: 8)
        let questions = builder.build(mode: .satsPractice, yearGroup: 6, stats: [:], using: &rng)
        #expect(questions.count == SessionMode.satsPractice.defaultLength)
        #expect(questions.allSatisfy { $0.satsStyle })
        #expect(Set(questions.map(\.strand)).count >= 2, "A SATs paper should mix grammar, punctuation and vocabulary")
        #expect(!SessionMode.satsPractice.givesInstantFeedback)
    }

    @Test func dailyPracticeForYoungerPupilsNeverUsesSatsQuestions() {
        var rng = SeededGenerator(seed: 10)
        for year in 1...4 {
            let questions = builder.build(mode: .daily, yearGroup: year, stats: [:], using: &rng)
            #expect(!questions.isEmpty, "Year \(year) has no daily practice")
            #expect(questions.allSatisfy { !$0.satsStyle && $0.yearGroup <= year }, "Year \(year) got SATs or older questions")
        }
    }

    @Test func emptyPoolGivesEmptySession() {
        var rng = SeededGenerator(seed: 9)
        #expect(builder.build(mode: .objective("NOPE"), yearGroup: 4, stats: [:], using: &rng).isEmpty)
    }
}
