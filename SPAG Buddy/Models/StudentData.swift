//
//  StudentData.swift
//  SPAG Buddy
//
//  Student profile and performance tracking
//

import Combine
import Foundation

// MARK: - Student Profile
struct StudentProfile: Codable {
    var level: Int = 1
    var experiencePoints: Int = 0
}

// MARK: - Topic Performance
struct TopicPerformance: Codable {
    var averageScore: Double
    var attempts: [QuizAttempt]
}

// MARK: - Quiz Attempt
struct QuizAttempt: Codable {
    let score: Int
    let total: Int
    let date: Date
}

// MARK: - Student Data Manager
class StudentData: ObservableObject {
    @Published var studentProfile = StudentProfile()
    @Published var performanceHistory: [String: TopicPerformance] = [:]

    private static let profileKey = "studentProfile"
    private static let historyKey = "performanceHistory"

    init() {
        loadData()
    }

    func recordAttempt(topic: String, score: Int, total: Int) {
        let attempt = QuizAttempt(score: score, total: total, date: Date())

        if var existing = performanceHistory[topic] {
            existing.attempts.append(attempt)
            let totalScore = existing.attempts.reduce(0.0) { $0 + (Double($1.score) / Double($1.total) * 100) }
            existing.averageScore = totalScore / Double(existing.attempts.count)
            performanceHistory[topic] = existing
        } else {
            let percentage = Double(score) / Double(total) * 100
            performanceHistory[topic] = TopicPerformance(averageScore: percentage, attempts: [attempt])
        }

        // Award XP
        let xpEarned = score * 10
        studentProfile.experiencePoints += xpEarned
        studentProfile.level = (studentProfile.experiencePoints / 1000) + 1

        saveData()
    }

    func getRecommendedTopics() -> [String] {
        let weakTopics = performanceHistory.filter { $0.value.averageScore < 70 }
        return Array(weakTopics.keys.prefix(5))
    }

    private func loadData() {
        let decoder = JSONDecoder()

        if let profileData = UserDefaults.standard.data(forKey: Self.profileKey),
           let profile = try? decoder.decode(StudentProfile.self, from: profileData) {
            studentProfile = profile
        }

        if let historyData = UserDefaults.standard.data(forKey: Self.historyKey),
           let history = try? decoder.decode([String: TopicPerformance].self, from: historyData) {
            performanceHistory = history
        }
    }

    private func saveData() {
        let encoder = JSONEncoder()

        if let profileData = try? encoder.encode(studentProfile) {
            UserDefaults.standard.set(profileData, forKey: Self.profileKey)
        }

        if let historyData = try? encoder.encode(performanceHistory) {
            UserDefaults.standard.set(historyData, forKey: Self.historyKey)
        }
    }
}
