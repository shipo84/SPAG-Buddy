//
//  QuizQuestion.swift
//  SPAG Buddy
//
//  Core quiz question model used throughout the app
//

import Foundation

struct QuizQuestion: Identifiable {
    let id = UUID()
    let question: String
    let options: [String]
    let correctAnswers: [String]
    let explanation: String

    init(_ question: String, _ options: [String], _ correctAnswers: [String], _ explanation: String) {
        self.question = question
        self.options = options
        self.correctAnswers = correctAnswers
        self.explanation = explanation
    }
}
