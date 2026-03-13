//
//  LegacyJSONQuestion.swift
//  SPAG Buddy
//
//  Legacy JSON question format for backward compatibility
//

import Foundation

struct LegacyJSONQuestion {
    let type: String?
    let question: String?
    let options: [String]?
    let answer: String?
    let explanation: String?
    let QuestionType: String?
    let Question: String?
    let Options: [String]?
    let Answer: String?
    let Explanation: String?

    func toEnhancedQuestion(withId id: String, pattern: String) -> EnhancedSpellingQuestion? {
        let questionText = question ?? Question ?? ""
        let answerText = answer ?? Answer ?? ""
        let explanationText = explanation ?? Explanation ?? ""
        let optionsList = options ?? Options ?? []
        let typeText = type ?? QuestionType ?? "multiple_choice"

        guard !questionText.isEmpty, !answerText.isEmpty else { return nil }

        return EnhancedSpellingQuestion(
            id: id,
            question: questionText,
            questionType: SpellingQuestionType(rawValue: typeText.lowercased()) ?? .multipleChoice,
            options: optionsList,
            correctAnswers: [answerText],
            explanation: explanationText,
            difficulty: 2,
            spellingPattern: pattern,
            yearGroup: [5, 6],
            commonMistakes: nil,
            hints: nil,
            contextSentence: nil,
            relatedWords: nil
        )
    }
}
