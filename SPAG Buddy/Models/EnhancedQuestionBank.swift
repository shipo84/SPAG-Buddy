//
//  EnhancedQuestionBank.swift
//  SPAG Buddy
//
//  Question bank with metadata for enhanced question management
//

import Foundation

struct EnhancedQuestionBank: Codable {
    struct QuestionBankMetadata: Codable {
        let topic: String
        let yearGroups: [Int]
        let lastUpdated: String
        let totalQuestions: Int
        let difficultyDistribution: [String: Int]
    }

    let metadata: QuestionBankMetadata
    let questions: [EnhancedSpellingQuestion]
}
