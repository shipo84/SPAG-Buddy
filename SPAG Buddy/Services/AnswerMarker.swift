import Foundation

enum PupilAnswer: Hashable, Sendable {
    case choice(String)
    case choices(Set<String>)
    case text(String)
    case gaps(Set<Int>)
}

struct MarkResult: Equatable, Sendable {
    var correct: Bool
    /// What the pupil answered, in a form a teacher can read. Stored with the attempt.
    var answerGiven: String
}

enum AnswerMarker {
    static let maxAnswerLength = 200

    static func mark(_ answer: PupilAnswer, for question: Question) -> MarkResult {
        switch (question.type, answer) {
        case (.multipleChoice, .choice(let choice)):
            return MarkResult(correct: question.answers.contains(choice), answerGiven: truncate(choice))

        case (.multiSelect, .choices(let chosen)):
            let given = question.choices.filter(chosen.contains).joined(separator: " | ")
            return MarkResult(correct: chosen == Set(question.answers), answerGiven: truncate(given))

        case (.spelling, .text(let text)):
            let typed = normalise(text)
            let correct = question.answers.contains { expected in
                expected.contains(where: \.isUppercase) ? typed == expected : typed.lowercased() == expected.lowercased()
            }
            return MarkResult(correct: correct, answerGiven: truncate(typed))

        case (.rewrite, .text(let text)):
            let typed = normalise(text)
            let correct = question.answers.contains { normalise($0) == typed }
            return MarkResult(correct: correct, answerGiven: truncate(typed))

        case (.tapGap, .gaps(let gaps)):
            return MarkResult(
                correct: gaps == question.gapAnswers,
                answerGiven: truncate(render(tokens: question.tokens, mark: question.mark ?? "", gaps: gaps))
            )

        default:
            return MarkResult(correct: false, answerGiven: "")
        }
    }

    /// Straightens curly quotes and apostrophes, trims and collapses whitespace.
    /// Capital letters and punctuation are kept because they are what SPAG tests.
    static func normalise(_ text: String) -> String {
        let replacements: [Character: Character] = [
            "\u{2018}": "'", "\u{2019}": "'", "\u{201C}": "\"", "\u{201D}": "\"",
            "\u{2013}": "-", "\u{00A0}": " ",
        ]
        let straightened = String(text.map { replacements[$0] ?? $0 })
        return straightened
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// Joins tokens with the mark placed after each chosen gap, e.g. "After lunch, we played."
    static func render(tokens: [String], mark: String, gaps: Set<Int>) -> String {
        var sentence = ""
        for (index, token) in tokens.enumerated() {
            if index > 0 { sentence += " " }
            sentence += token
            if gaps.contains(index) { sentence += mark }
        }
        return sentence
    }

    private static func truncate(_ text: String) -> String {
        text.count > maxAnswerLength ? String(text.prefix(maxAnswerLength)) : text
    }
}
