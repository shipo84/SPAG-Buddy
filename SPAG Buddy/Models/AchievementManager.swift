//
//  AchievementManager.swift
//  SPAG Buddy
//
//  Manages achievement unlocking and tracking
//

import Foundation

class AchievementManager: ObservableObject {
    @Published var unlockedAchievements: Set<String> = []

    init() {
        loadUnlockedAchievements()
    }

    func checkAndUnlockAchievements(studentData: StudentData, currentStreak: Int) {
        // Check streak achievements
        if currentStreak >= 3 {
            unlock("streak_3")
        }
        if currentStreak >= 7 {
            unlock("streak_7")
        }

        // Check level achievements
        if studentData.studentProfile.level >= 5 {
            unlock("level_5")
        }
        if studentData.studentProfile.level >= 10 {
            unlock("level_10")
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
