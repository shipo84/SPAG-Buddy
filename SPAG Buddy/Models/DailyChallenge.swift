//
//  DailyChallenge.swift
//  SPAG Buddy
//
//  Daily challenge model and manager
//

import Combine
import SwiftUI

// MARK: - Daily Challenge Question
struct DailyChallengeQuestion {
    let text: String
    let options: [String]
    let correctAnswer: String
}

// MARK: - Daily Challenge
struct DailyChallenge {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let questions: [DailyChallengeQuestion]
    let bonusXP: Int
}

// MARK: - Daily Challenge Manager
class DailyChallengeManager: ObservableObject {
    @Published var todaysChallenge: DailyChallenge?
    @Published var isChallengeCompleted = false
    @Published var dailyChallengeStreak = 0

    /// Source files for mixed-category daily challenge questions.
    /// One file per category so the challenge covers all SPAG areas.
    private static let sourceFiles: [(filename: String, category: String)] = [
        ("Homophones_Enhanced", "Spelling"),
        ("Apostrophes", "Punctuation"),
        ("Adjectives", "Grammar"),
        ("SynonymsAndAntonyms", "Vocabulary"),
        ("SilentLetters", "Spelling"),
        ("ColonsSemicolons", "Punctuation"),
        ("Clauses", "Grammar"),
        ("Prefixes", "Vocabulary"),
        ("CommasInLists", "Punctuation"),
        ("DroppingSilentE", "Spelling")
    ]

    init() {
        loadStreak()
        loadChallenge()
    }

    func completeChallenge(score: Int, totalQuestions: Int) {
        isChallengeCompleted = true
        dailyChallengeStreak += 1

        UserDefaults.standard.set(Date(), forKey: "lastChallengeDate")
        UserDefaults.standard.set(dailyChallengeStreak, forKey: "dailyChallengeStreak")
    }

    private func loadChallenge() {
        // Check if already completed today
        if let lastDate = UserDefaults.standard.object(forKey: "lastChallengeDate") as? Date {
            isChallengeCompleted = Calendar.current.isDateInToday(lastDate)
        }

        // Build questions from JSON, seeded by today's date so the set changes daily
        let questions = buildDailyQuestions(count: 5)

        todaysChallenge = DailyChallenge(
            title: "Daily SPAG Challenge",
            description: "Test your skills with today's mixed questions!",
            icon: "star.circle.fill",
            color: .blue,
            questions: questions,
            bonusXP: 50
        )
    }

    /// Loads questions from JSON resources and picks a reproducible daily set.
    private func buildDailyQuestions(count: Int) -> [DailyChallengeQuestion] {
        // Collect questions from several source files
        var pool: [DailyChallengeQuestion] = []

        for source in Self.sourceFiles {
            let loaded = QuestionLoaderService.loadQuestions(from: source.filename)
            for q in loaded {
                guard !q.options.isEmpty, !q.correctAnswers.isEmpty else { continue }
                pool.append(DailyChallengeQuestion(
                    text: q.question,
                    options: q.options,
                    correctAnswer: q.correctAnswers.first ?? ""
                ))
            }
        }

        guard !pool.isEmpty else {
            // Fallback if no JSON loaded
            return fallbackQuestions()
        }

        // Seed a random generator with today's date so the selection is stable for the day
        let daysSinceEpoch = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        var rng = SeededRandomNumberGenerator(seed: UInt64(daysSinceEpoch))
        pool.shuffle(using: &rng)

        return Array(pool.prefix(count))
    }

    private func fallbackQuestions() -> [DailyChallengeQuestion] {
        [
            DailyChallengeQuestion(text: "Which word is spelled correctly?", options: ["recieve", "receive", "receve", "receeve"], correctAnswer: "receive"),
            DailyChallengeQuestion(text: "Which sentence uses an apostrophe correctly?", options: ["The dog's bowl is empty.", "The dogs' bowl is empty.", "The dog bowl's is empty.", "The dogs bowl is empty."], correctAnswer: "The dog's bowl is empty."),
            DailyChallengeQuestion(text: "What is a synonym for 'happy'?", options: ["Sad", "Joyful", "Angry", "Tired"], correctAnswer: "Joyful"),
            DailyChallengeQuestion(text: "Which word is an adverb?", options: ["Quick", "Quickly", "Quicker", "Quickest"], correctAnswer: "Quickly"),
            DailyChallengeQuestion(text: "Choose the correct homophone: 'I can ___ the birds.'", options: ["here", "hear", "heer", "hare"], correctAnswer: "hear")
        ]
    }

    private func loadStreak() {
        dailyChallengeStreak = UserDefaults.standard.integer(forKey: "dailyChallengeStreak")

        // Reset streak if missed a day
        if let lastDate = UserDefaults.standard.object(forKey: "lastChallengeDate") as? Date {
            if !Calendar.current.isDateInToday(lastDate) && !Calendar.current.isDateInYesterday(lastDate) {
                dailyChallengeStreak = 0
                UserDefaults.standard.set(0, forKey: "dailyChallengeStreak")
            }
        }
    }
}

// MARK: - Seeded Random Number Generator
/// Simple deterministic RNG so daily challenge picks are stable per day.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
