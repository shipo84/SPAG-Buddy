//
//  Achievement.swift
//  SPAG Buddy
//
//  Achievement model and definitions
//

import SwiftUI

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let points: Int

    static let allAchievements: [Achievement] = [
        Achievement(id: "first_quiz", title: "First Steps", description: "Complete your first quiz", icon: "star.fill", color: .yellow, points: 10),
        Achievement(id: "perfect_score", title: "Perfect Score", description: "Get 100% on any quiz", icon: "crown.fill", color: .purple, points: 50),
        Achievement(id: "streak_3", title: "On a Roll", description: "Complete 3 daily challenges in a row", icon: "flame.fill", color: .orange, points: 30),
        Achievement(id: "streak_7", title: "Week Warrior", description: "Complete 7 daily challenges in a row", icon: "bolt.fill", color: .red, points: 75),
        Achievement(id: "spelling_master", title: "Spelling Star", description: "Master all spelling topics", icon: "textformat.abc", color: .blue, points: 100),
        Achievement(id: "grammar_guru", title: "Grammar Guru", description: "Master all grammar topics", icon: "text.book.closed.fill", color: .green, points: 100),
        Achievement(id: "punctuation_pro", title: "Punctuation Pro", description: "Master all punctuation topics", icon: "pencil.circle.fill", color: .mint, points: 100),
        Achievement(id: "vocabulary_victor", title: "Vocabulary Victor", description: "Master all vocabulary topics", icon: "character.book.closed.fill", color: .indigo, points: 100),
        Achievement(id: "level_5", title: "Rising Star", description: "Reach Level 5", icon: "star.circle.fill", color: .cyan, points: 40),
        Achievement(id: "level_10", title: "SPAG Champion", description: "Reach Level 10", icon: "trophy.fill", color: .yellow, points: 100)
    ]
}
