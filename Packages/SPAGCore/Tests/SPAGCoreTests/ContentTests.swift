import Foundation
import Testing
@testable import SPAGCore

@MainActor
struct ContentTests {
    let library = TestContent.library

    @Test func everyManifestFileLoads() {
        #expect(!library.questions.isEmpty)
        #expect(!library.objectives.isEmpty)
        #expect(library.avatars.count >= 30)
    }

    /// Both apps load this at launch and stop if it fails.
    @Test func bundledContentMatchesTheContentFolder() throws {
        let bundled = try ContentLibrary.loadBundled()
        #expect(bundled.manifest.contentVersion == library.manifest.contentVersion)
        #expect(bundled.questions.count == library.questions.count)
    }

    @Test func questionIdsAreUnique() {
        let ids = library.questions.map(\.id)
        let duplicates = Dictionary(grouping: ids, by: { $0 }).filter { $0.value.count > 1 }.keys
        #expect(duplicates.isEmpty, "Duplicate question ids: \(duplicates.sorted())")
    }

    @Test func objectiveCodesMatchTheirYearAndStrand() {
        let strandLetters: [Strand: String] = [.spelling: "S", .punctuation: "P", .grammar: "G", .vocabulary: "V"]
        for objective in library.objectives.values {
            let parts = objective.code.split(separator: "-")
            #expect(parts.count >= 3, "\(objective.code) should look like Y4-G-name")
            #expect(parts.first?.hasPrefix("Y\(objective.yearGroup)") == true, "\(objective.code) year prefix")
            #expect(String(parts[1]) == strandLetters[objective.strand], "\(objective.code) strand letter")
            #expect((1...6).contains(objective.yearGroup))
            #expect(!objective.rule.isEmpty && !objective.childTitle.isEmpty)
        }
    }

    @Test func everyQuestionIsAnswerable() {
        for question in library.questions {
            #expect(!question.answers.isEmpty, "\(question.id) has no answers")
            #expect(!question.explanation.isEmpty, "\(question.id) has no explanation")

            switch question.type {
            case .multipleChoice:
                #expect(question.choices.count >= 2, "\(question.id) needs choices")
                #expect(question.answers.count == 1, "\(question.id) should have one answer")
                #expect(question.answers.allSatisfy(question.choices.contains), "\(question.id) answer is not a choice")
            case .multiSelect:
                #expect(question.answers.count >= 2, "\(question.id) should have several answers")
                #expect(question.answers.allSatisfy(question.choices.contains), "\(question.id) answer is not a choice")
            case .tapGap:
                #expect(question.mark?.isEmpty == false, "\(question.id) needs a mark")
                #expect(question.gapAnswers.count == question.answers.count, "\(question.id) gap answers must be numbers")
                #expect(question.gapAnswers.allSatisfy { (0..<(question.tokens.count - 1)).contains($0) },
                        "\(question.id) gap index is outside the sentence")
            case .spelling:
                #expect(question.answers.count == 1)
                #expect(question.audioText.contains(question.answers[0]), "\(question.id) must say the word")
            case .rewrite:
                #expect(question.answers.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
            }

            if let highlight = question.highlight {
                #expect(question.prompt.contains(highlight), "\(question.id) highlight is not in the prompt")
            }
        }
    }

    @Test func correctAnswersMarkAsCorrect() {
        for question in library.questions {
            let answer: PupilAnswer
            switch question.type {
            case .multipleChoice: answer = .choice(question.answers[0])
            case .multiSelect: answer = .choices(Set(question.answers))
            case .tapGap: answer = .gaps(question.gapAnswers)
            case .spelling, .rewrite: answer = .text(question.answers[0])
            }
            #expect(AnswerMarker.mark(answer, for: question).correct, "\(question.id) rejects its own answer")
        }
    }

    @Test func everyObjectiveInALoadedYearHasQuestions() {
        let loadedYears = Set(library.questions.filter { $0.type != .spelling }.map(\.yearGroup))
        for objective in library.objectives.values where loadedYears.contains(objective.yearGroup) {
            let count = library.questions.filter { $0.objectiveCode == objective.code }.count
            #expect(count >= 3, "\(objective.code) only has \(count) questions")
        }
    }

    @Test func everyYearHasWrittenQuestionsAndYear6IsSatsStyle() {
        let written = library.questions.filter { $0.type != .spelling || !$0.id.hasPrefix("spell-") }
        for year in 1...6 {
            #expect(written.contains { $0.yearGroup == year }, "Year \(year) has no questions")
        }
        #expect(written.filter { $0.yearGroup == 6 }.allSatisfy { $0.satsStyle })
        #expect(written.filter { $0.yearGroup < 6 }.allSatisfy { !$0.satsStyle })
    }

    @Test func spellingListsCoverStatutoryWords() {
        // Statutory lists have 100 entries each; variants such as accident(ally) are listed as separate words.
        #expect(library.spellingList(id: "y34-statutory")?.words.count == 109)
        #expect(library.spellingList(id: "y56-statutory")?.words.count == 103)
        #expect(library.spellingLists(forYear: 4).contains { $0.id == "y34-statutory" })
    }

    @Test func spellingQuestionIdsAreStable() {
        #expect(SpellingQuestionFactory.questionId(listId: "y2-cew", word: "Mrs") == "spell-y2-cew-mrs")
        #expect(SpellingQuestionFactory.slug("  Hello,  World! ") == "hello-world")
        #expect(library.question(id: "spell-y34-statutory-february")?.answers == ["February"])
    }
}
