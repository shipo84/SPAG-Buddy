//
//  DailyChallenge.swift
//  SPAG Buddy
//
//  Daily challenge model and manager
//

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

    init() {
        loadChallenge()
        loadStreak()
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

        // Generate today's challenge
        todaysChallenge = DailyChallenge(
            title: "Daily SPAG Challenge",
            description: "Test your skills with today's mixed questions!",
            icon: "star.circle.fill",
            color: .blue,
            questions: [
                DailyChallengeQuestion(text: "Which word is spelled correctly?", options: ["recieve", "receive", "receve", "receeve"], correctAnswer: "receive"),
                DailyChallengeQuestion(text: "Which sentence uses an apostrophe correctly?", options: ["The dog's bowl is empty.", "The dogs' bowl is empty.", "The dog bowl's is empty.", "The dogs bowl is empty."], correctAnswer: "The dog's bowl is empty."),
                DailyChallengeQuestion(text: "What is a synonym for 'happy'?", options: ["Sad", "Joyful", "Angry", "Tired"], correctAnswer: "Joyful"),
                DailyChallengeQuestion(text: "Which word is an adverb?", options: ["Quick", "Quickly", "Quicker", "Quickest"], correctAnswer: "Quickly"),
                DailyChallengeQuestion(text: "Choose the correct homophone: 'I can ___ the birds.'", options: ["here", "hear", "heer", "hare"], correctAnswer: "hear")
            ],
            bonusXP: 50
        )
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
