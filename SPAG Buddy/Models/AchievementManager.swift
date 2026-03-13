//
//  AchievementManager.swift
//  SPAG Buddy
//
//  Manages achievement unlocking and tracking
//

import Combine
import Foundation

class AchievementManager: ObservableObject {
    @Published var unlockedAchievements: Set<String> = []

    init() {
        loadUnlockedAchievements()
    }

    /// Full achievement check — call after every quiz or daily challenge completion.
    func checkAndUnlockAchievements(
        studentData: StudentData,
        currentStreak: Int,
        latestScore: Int? = nil,
        latestTotal: Int? = nil
    ) {
        // First quiz completed
        let totalAttempts = studentData.performanceHistory.values.reduce(0) { $0 + $1.attempts.count }
        if totalAttempts >= 1 {
            unlock("first_quiz")
        }

        // Perfect score on any quiz
        if let score = latestScore, let total = latestTotal, score == total, total > 0 {
            unlock("perfect_score")
        }

        // Streak achievements
        if currentStreak >= 3 {
            unlock("streak_3")
        }
        if currentStreak >= 7 {
            unlock("streak_7")
        }

        // Level achievements
        if studentData.studentProfile.level >= 5 {
            unlock("level_5")
        }
        if studentData.studentProfile.level >= 10 {
            unlock("level_10")
        }

        // Category mastery — all topics in category have averageScore >= 80
        let masteryThreshold: Double = 80

        let spellingTopics = SPAGCategory.spelling.topics.map { $0.name }
        if !spellingTopics.isEmpty && spellingTopics.allSatisfy({ (studentData.performanceHistory[$0]?.averageScore ?? 0) >= masteryThreshold }) {
            unlock("spelling_master")
        }

        let grammarTopics = SPAGCategory.grammar.topics.map { $0.name }
        if !grammarTopics.isEmpty && grammarTopics.allSatisfy({ (studentData.performanceHistory[$0]?.averageScore ?? 0) >= masteryThreshold }) {
            unlock("grammar_guru")
        }

        let punctuationTopics = SPAGCategory.punctuation.topics.map { $0.name }
        if !punctuationTopics.isEmpty && punctuationTopics.allSatisfy({ (studentData.performanceHistory[$0]?.averageScore ?? 0) >= masteryThreshold }) {
            unlock("punctuation_pro")
        }

        let vocabularyTopics = SPAGCategory.vocabulary.topics.map { $0.name }
        if !vocabularyTopics.isEmpty && vocabularyTopics.allSatisfy({ (studentData.performanceHistory[$0]?.averageScore ?? 0) >= masteryThreshold }) {
            unlock("vocabulary_victor")
        }

        saveUnlockedAchievements()
    }

    func unlock(_ achievementId: String) {
        unlockedAchievements.insert(achievementId)
    }

    private func loadUnlockedAchievements() {
        if let saved = UserDefaults.standard.array(forKey: "unlockedAchievements") as? [String] {
            unlockedAchievements = Set(saved)
        }
    }

    private func saveUnlockedAchievements() {
        UserDefaults.standard.set(Array(unlockedAchievements), forKey: "unlockedAchievements")
    }
}
