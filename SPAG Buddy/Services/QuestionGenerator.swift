//
//  QuestionGenerator.swift
//  SPAG Buddy
//
//  Dynamic question generation for different topics
//

import Foundation

// MARK: - Question Generator Service
class QuestionGenerator: ObservableObject {

    // MARK: - Spelling Question Templates
    private let spellingTemplates = [
        "Choose the correct spelling: {word1} / {word2}",
        "Which word is spelled correctly: {options}",
        "Add the correct ending: {stem}___"
    ]

    // MARK: - Grammar Question Templates
    private let grammarTemplates = [
        "Choose the correct word: {sentence_with_blank}",
        "Identify the {part_of_speech} in this sentence: {sentence}",
        "Which sentence is grammatically correct?"
    ]

    // MARK: - Vocabulary Question Templates
    private let vocabularyTemplates = [
        "What does '{word}' mean?",
        "Which word is a synonym for '{word}'?",
        "Which word is an antonym for '{word}'?"
    ]

    // MARK: - Question Generation Methods
    func generateSpellingQuestion(difficulty: QuestionDifficulty) -> QuizQuestion {
        // TODO: Implement dynamic spelling question generation
        return QuizQuestion(
            "Sample spelling question",
            ["option1", "option2"],
            ["option1"],
            "Sample explanation"
        )
    }

    func generateGrammarQuestion(difficulty: QuestionDifficulty) -> QuizQuestion {
        // TODO: Implement dynamic grammar question generation
        return QuizQuestion(
            "Sample grammar question",
            ["option1", "option2"],
            ["option1"],
            "Sample explanation"
        )
    }

    func generateVocabularyQuestion(difficulty: QuestionDifficulty) -> QuizQuestion {
        // TODO: Implement dynamic vocabulary question generation
        return QuizQuestion(
            "Sample vocabulary question",
            ["option1", "option2"],
            ["option1"],
            "Sample explanation"
        )
    }

    func generateQuestionsForTopic(_ topic: String, count: Int = 10) -> [QuizQuestion] {
        // TODO: Generate questions based on topic
        var questions: [QuizQuestion] = []

        for i in 1...count {
            questions.append(QuizQuestion(
                "Sample question \(i) for \(topic)",
                ["option1", "option2", "option3"],
                ["option1"],
                "Sample explanation for question \(i)"
            ))
        }

        return questions
    }
}

// MARK: - Supporting Enums
enum QuestionDifficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var pointValue: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
}
