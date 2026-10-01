import Foundation
import SwiftData

/// Deletes Home data. Nothing is kept anywhere else, so every deletion here is permanent.
enum HomeDataEraser {
    /// Clears answers, stars, stickers and streaks. The name, picture, year and reading settings stay.
    static func deleteProgress(of child: PupilProfile, in context: ModelContext) throws {
        for attempt in child.attempts { context.delete(attempt) }
        for badge in child.badges { context.delete(badge) }
        child.stars = 0
        child.currentStreak = 0
        child.longestStreak = 0
        child.lastPracticeDay = nil
        child.sessionsCompleted = 0
        child.satsSessionsCompleted = 0
        try context.save()
    }

    static func deleteChild(_ child: PupilProfile, in context: ModelContext) throws {
        context.delete(child)
        try context.save()
    }

    /// Removes every child and all their progress, then clears the app's settings on this iPad.
    static func deleteEverything(
        in context: ModelContext,
        defaults: UserDefaults = .standard,
        defaultsDomain: String? = Bundle.main.bundleIdentifier
    ) throws {
        for child in try context.fetch(FetchDescriptor<PupilProfile>()) {
            context.delete(child)
        }
        try context.delete(model: Attempt.self)
        try context.delete(model: BadgeProgress.self)
        try context.save()

        if let defaultsDomain {
            defaults.removePersistentDomain(forName: defaultsDomain)
        }
    }
}
