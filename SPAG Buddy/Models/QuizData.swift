//
//  QuizData.swift
//  SPAG Buddy
//
//  Quiz data tracking and analytics
//

import Combine
import Foundation

// MARK: - Quiz Attempt Record
struct QuizAttemptRecord: Identifiable {
    let id = UUID()
    let topic: String
    let score: Int
    let totalQuestions: Int
    let date: Date

    // Backward-compatible alias
    var total: Int { totalQuestions }
}

// MARK: - Quiz Data Manager
class QuizData: ObservableObject {
    @Published var topicHistory: [String: [QuizAttemptRecord]] = [:]

    /// All attempts across all topics, sorted by date
    var attempts: [QuizAttemptRecord] {
        topicHistory.values.flatMap { $0 }.sorted { $0.date < $1.date }
    }

    func recordAttempt(topic: String, score: Int, total: Int) {
        let record = QuizAttemptRecord(topic: topic, score: score, totalQuestions: total, date: Date())
        if topicHistory[topic] != nil {
            topicHistory[topic]?.append(record)
        } else {
            topicHistory[topic] = [record]
        }
    }

    /// Average score across all topics
    func getAverageScore() -> Double {
        let allAttempts = attempts
        guard !allAttempts.isEmpty else { return 0 }
        let totalPercentage = allAttempts.reduce(0.0) { $0 + (Double($1.score) / Double($1.totalQuestions) * 100) }
        return totalPercentage / Double(allAttempts.count)
    }

    func getAverageScore(topic: String) -> Double {
        guard let attempts = topicHistory[topic], !attempts.isEmpty else { return 0 }
        let totalPercentage = attempts.reduce(0.0) { $0 + (Double($1.score) / Double($1.totalQuestions) * 100) }
        return totalPercentage / Double(attempts.count)
    }

    func getTopicHistory(topic: String) -> [QuizAttemptRecord] {
        return topicHistory[topic] ?? []
    }
}
