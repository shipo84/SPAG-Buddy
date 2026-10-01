import Foundation
import SwiftData
import Testing
@testable import SPAG_Buddy

@MainActor
struct HomeFamilyTests {
    @Test func allowsUpToFourChildren() {
        #expect(HomeFamily.maxChildren == 4)
        #expect(HomeFamily.canAddChild(existingCount: 0))
        #expect(HomeFamily.canAddChild(existingCount: 3))
        #expect(!HomeFamily.canAddChild(existingCount: 4))
    }

    @Test func namesAreTrimmedAndShort() {
        #expect(HomeFamily.cleanedName("  Mia \n") == "Mia")
        #expect(HomeFamily.cleanedName(String(repeating: "a", count: 40)).count == HomeFamily.maxNameLength)
    }

    @Test func namesMustBePresentAndDifferent() {
        #expect(HomeFamily.nameProblem("   ", existingNames: []) == .empty)
        #expect(HomeFamily.nameProblem("mia", existingNames: ["Mia"]) == .alreadyUsed)
        #expect(HomeFamily.nameProblem("Zoë", existingNames: ["Zoe"]) == .alreadyUsed)
        #expect(HomeFamily.nameProblem("Sam", existingNames: ["Mia"]) == nil)
    }

    @Test func linksAreTheHomeWebsite() {
        #expect(HomeLinks.privacyPolicy.absoluteString == "https://digitalclubhouse.org/spag-buddy/home/privacy/")
        #expect(HomeLinks.spagBuddySchool.scheme == "https")
    }
}

@MainActor
struct HomeDataNoticeTests {
    private var fullText: String {
        ([HomeDataNotice.headline] + HomeDataNotice.sections.map(\.body)).joined(separator: " ")
    }

    @Test func saysEverythingStaysOnTheIPad() {
        #expect(HomeDataNotice.headline == "Everything stays on this iPad. Nothing is sent to us or anyone else.")
    }

    @Test func explainsDeletionAndThatProgressCannotMoveToSchool() {
        let titles = HomeDataNotice.sections.map(\.title)
        #expect(titles.contains("Deleting it"))
        #expect(titles.contains("SPAG Buddy School"))
        #expect(fullText.contains("cannot be moved to SPAG Buddy School"))
    }

    @Test func neverMentionsClassesOrTeachers() {
        let text = fullText.lowercased()
        #expect(!text.contains("teacher"))
        #expect(!text.contains("class code"))
        #expect(!fullText.contains("PIN"))
    }

    @Test func sentencesAreShort() {
        for section in HomeDataNotice.sections {
            for sentence in section.body.split(whereSeparator: { ".!?".contains($0) }) {
                let words = sentence.split(separator: " ").count
                #expect(words <= 30, "\"\(sentence)\" has \(words) words")
            }
        }
    }
}

@MainActor
struct HomeProgressSummaryTests {
    private let objectives = Array(TestContent.library.objectives.values)

    private func attempts(_ results: [Bool], objective: Objective) -> [AttemptRecord] {
        results.enumerated().map { index, correct in
            AttemptRecord(
                questionId: "q\(index)",
                objectiveCode: objective.code,
                strand: objective.strand,
                correct: correct,
                answeredAt: Date(timeIntervalSince1970: Double(index))
            )
        }
    }

    @Test func showsTheChildsYearAndTheYearBelow() throws {
        let topics = HomeProgressSummary.topics(objectives: objectives, attempts: [], yearGroup: 4)
        #expect(!topics.isEmpty)
        #expect(topics.map(\.strand) == Strand.allCases.filter { strand in topics.contains { $0.strand == strand } })
        for topic in topics {
            #expect(topic.skills.allSatisfy { [3, 4].contains($0.objective.yearGroup) })
            #expect(topic.answered == 0)
            #expect(topic.count(.notStarted) == topic.skills.count)
        }
    }

    @Test func includesSkillsPractisedInOtherYears() throws {
        let yearOne = try #require(objectives.first { $0.yearGroup == 1 })
        let topics = HomeProgressSummary.topics(objectives: objectives, attempts: attempts([false], objective: yearOne), yearGroup: 5)
        #expect(topics.contains { $0.skills.contains { $0.objective.code == yearOne.code } })
    }

    @Test func countsAnswersAndLevelsPerTopic() throws {
        let skill = try #require(objectives.first { $0.yearGroup == 4 && $0.strand == .grammar })
        let topics = HomeProgressSummary.topics(objectives: objectives, attempts: attempts([true, true, true, true, false], objective: skill), yearGroup: 4)
        let grammar = try #require(topics.first { $0.strand == .grammar })
        #expect(grammar.answered == 5)
        #expect(grammar.correct == 4)
        #expect(grammar.count(.secure) == 1)
        #expect(grammar.count(.notStarted) == grammar.skills.count - 1)
    }
}

@MainActor
struct HomeDataEraserTests {
    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return ModelContext(try ModelContainer(for: SPAG_BuddyApp.schema, configurations: configuration))
    }

    private func child(_ name: String, practised answers: Int, in context: ModelContext) -> PupilProfile {
        let child = PupilProfile(displayName: name, avatarKey: "fox", yearGroup: 4)
        context.insert(child)
        let question = TestContent.question(.multipleChoice, choices: ["a", "b"], answers: ["a"])
        for _ in 0..<answers {
            context.insert(Attempt(
                pupil: child,
                question: question,
                result: MarkResult(correct: true, answerGiven: "a"),
                timeTakenMs: 1000,
                hintUsed: false,
                sessionId: UUID(),
                mode: .daily
            ))
        }
        context.insert(BadgeProgress(badgeId: "first-steps", pupil: child))
        child.stars = 12
        child.currentStreak = 2
        child.longestStreak = 3
        child.lastPracticeDay = .now
        child.sessionsCompleted = 1
        child.highContrast = true
        return child
    }

    @Test func deletingProgressKeepsTheProfile() throws {
        let context = try makeContext()
        let mia = child("Mia", practised: 3, in: context)
        let sam = child("Sam", practised: 2, in: context)
        try context.save()

        try HomeDataEraser.deleteProgress(of: mia, in: context)

        #expect(try context.fetchCount(FetchDescriptor<PupilProfile>()) == 2)
        #expect(mia.attempts.isEmpty)
        #expect(mia.badges.isEmpty)
        #expect(mia.stars == 0)
        #expect(mia.currentStreak == 0 && mia.longestStreak == 0 && mia.lastPracticeDay == nil)
        #expect(mia.sessionsCompleted == 0)
        #expect(mia.displayName == "Mia" && mia.highContrast)
        #expect(sam.attempts.count == 2)
        #expect(try context.fetchCount(FetchDescriptor<Attempt>()) == 2)
    }

    @Test func removingAChildRemovesOnlyThatChild() throws {
        let context = try makeContext()
        let mia = child("Mia", practised: 3, in: context)
        _ = child("Sam", practised: 2, in: context)
        try context.save()

        try HomeDataEraser.deleteChild(mia, in: context)

        let names = try context.fetch(FetchDescriptor<PupilProfile>()).map(\.displayName)
        #expect(names == ["Sam"])
        #expect(try context.fetchCount(FetchDescriptor<Attempt>()) == 2)
        #expect(try context.fetchCount(FetchDescriptor<BadgeProgress>()) == 1)
    }

    @Test func deletingEverythingLeavesNothing() throws {
        let context = try makeContext()
        _ = child("Mia", practised: 3, in: context)
        _ = child("Sam", practised: 2, in: context)
        try context.save()

        let suite = "HomeDataEraserTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.set(UUID().uuidString, forKey: "activePupilID")
        defaults.set(true, forKey: "homeSetupComplete")

        try HomeDataEraser.deleteEverything(in: context, defaults: defaults, defaultsDomain: suite)

        #expect(try context.fetchCount(FetchDescriptor<PupilProfile>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Attempt>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<BadgeProgress>()) == 0)
        #expect(defaults.string(forKey: "activePupilID") == nil)
        #expect(defaults.object(forKey: "homeSetupComplete") == nil)
    }
}
