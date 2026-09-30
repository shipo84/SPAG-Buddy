import Testing
@testable import SPAG_Buddy

@MainActor
struct AnswerMarkerTests {
    @Test func multipleChoice() {
        let question = TestContent.question(.multipleChoice, choices: ["did", "done"], answers: ["did"])
        #expect(AnswerMarker.mark(.choice("did"), for: question) == MarkResult(correct: true, answerGiven: "did"))
        #expect(AnswerMarker.mark(.choice("done"), for: question) == MarkResult(correct: false, answerGiven: "done"))
    }

    @Test func multiSelectNeedsEveryAnswerAndNoExtras() {
        let question = TestContent.question(.multiSelect, choices: ["The", "cat", "some", "my"], answers: ["The", "some", "my"])
        #expect(AnswerMarker.mark(.choices(["The", "some", "my"]), for: question).correct)
        #expect(!AnswerMarker.mark(.choices(["The", "some"]), for: question).correct)
        #expect(!AnswerMarker.mark(.choices(["The", "some", "my", "cat"]), for: question).correct)
        #expect(AnswerMarker.mark(.choices(["my", "The"]), for: question).answerGiven == "The | my")
    }

    @Test func spellingIgnoresCaseUnlessTheWordNeedsACapital() {
        let lower = TestContent.question(.spelling, answers: ["island"])
        #expect(AnswerMarker.mark(.text(" Island "), for: lower).correct)
        #expect(!AnswerMarker.mark(.text("iland"), for: lower).correct)

        let proper = TestContent.question(.spelling, answers: ["February"])
        #expect(AnswerMarker.mark(.text("February"), for: proper).correct)
        #expect(!AnswerMarker.mark(.text("february"), for: proper).correct)
    }

    @Test func rewriteKeepsPunctuationButStraightensQuotes() {
        let question = TestContent.question(.rewrite, answers: ["\"Where is my hat?\" asked Grandad."])
        #expect(AnswerMarker.mark(.text("\u{201C}Where is my hat?\u{201D}  asked Grandad."), for: question).correct)
        #expect(!AnswerMarker.mark(.text("\"Where is my hat\" asked Grandad."), for: question).correct)
        #expect(!AnswerMarker.mark(.text("\"where is my hat?\" asked Grandad."), for: question).correct)
    }

    @Test func rewriteAcceptsCurlyApostrophes() {
        let question = TestContent.question(.rewrite, answers: ["I can't swim."])
        #expect(AnswerMarker.mark(.text("I can\u{2019}t swim."), for: question).correct)
    }

    @Test func tapGapRendersTheSentenceForTeachers() {
        let question = TestContent.question(.tapGap, tokens: ["After", "lunch", "we", "played."], mark: ",", answers: ["1"])
        #expect(AnswerMarker.mark(.gaps([1]), for: question) == MarkResult(correct: true, answerGiven: "After lunch, we played."))
        #expect(AnswerMarker.mark(.gaps([0]), for: question) == MarkResult(correct: false, answerGiven: "After, lunch we played."))
        #expect(!AnswerMarker.mark(.gaps([1, 2]), for: question).correct)
    }

    @Test func wrongAnswerShapeIsIncorrect() {
        let question = TestContent.question(.multipleChoice, choices: ["a", "b"], answers: ["a"])
        #expect(!AnswerMarker.mark(.text("a"), for: question).correct)
    }

    @Test func longAnswersAreTruncated() {
        let question = TestContent.question(.rewrite, answers: ["Short."])
        let result = AnswerMarker.mark(.text(String(repeating: "a", count: 500)), for: question)
        #expect(result.answerGiven.count == AnswerMarker.maxAnswerLength)
    }
}
