//
//  EnhancedSpellingQuestion.swift
//  SPAG Buddy
//
//  Enhanced question model with metadata for adaptive learning
//

import Foundation

// MARK: - Spelling Question Type
enum SpellingQuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case completePassage = "complete_passage"
    case findErrors = "find_errors"
    case complexChoice = "complex_choice"
    case writeSentences = "write_sentences"
}

// MARK: - Enhanced Spelling Question
struct EnhancedSpellingQuestion: Codable, Identifiable {
    let id: String
    let question: String
    let questionType: SpellingQuestionType
    let options: [String]
    let correctAnswers: [String]
    let explanation: String
    let difficulty: Int
    let spellingPattern: String
    let yearGroup: [Int]?
    let commonMistakes: [String]?
    let hints: [String]?
    let contextSentence: String?
    let relatedWords: [String]?

    var toQuizQuestion: QuizQuestion {
        QuizQuestion(question, options, correctAnswers, explanation)
    }
}
