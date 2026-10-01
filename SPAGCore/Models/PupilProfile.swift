import Foundation
import SwiftData

@Model
final class PupilProfile {
    @Attribute(.unique) var id: UUID
    /// First name or nickname only.
    var displayName: String
    var avatarKey: String
    var yearGroup: Int
    var createdAt: Date

    /// Set when the pupil has joined a class. `nil` means home practice only, and nothing is uploaded.
    var remotePupilId: String?
    var classCode: String?
    var className: String?
    var lastSyncedAt: Date?

    var easyReadText: Bool
    var highContrast: Bool
    var autoReadAloud: Bool

    var stars: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastPracticeDay: Date?
    var sessionsCompleted: Int
    var satsSessionsCompleted: Int

    @Relationship(deleteRule: .cascade, inverse: \Attempt.pupil)
    var attempts: [Attempt] = []

    @Relationship(deleteRule: .cascade, inverse: \BadgeProgress.pupil)
    var badges: [BadgeProgress] = []

    @Relationship(deleteRule: .cascade, inverse: \Assignment.pupil)
    var assignments: [Assignment] = []

    init(
        id: UUID = UUID(),
        displayName: String,
        avatarKey: String,
        yearGroup: Int,
        remotePupilId: String? = nil,
        classCode: String? = nil,
        className: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarKey = avatarKey
        self.yearGroup = yearGroup
        self.createdAt = .now
        self.remotePupilId = remotePupilId
        self.classCode = classCode
        self.className = className
        self.easyReadText = false
        self.highContrast = false
        self.autoReadAloud = yearGroup <= 2
        self.stars = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.sessionsCompleted = 0
        self.satsSessionsCompleted = 0
    }

    var isInClass: Bool { remotePupilId != nil }

    var streak: StreakCalculator.Streak {
        get { .init(current: currentStreak, longest: longestStreak, lastPracticeDay: lastPracticeDay) }
        set {
            currentStreak = newValue.current
            longestStreak = newValue.longest
            lastPracticeDay = newValue.lastPracticeDay
        }
    }

    var attemptRecords: [AttemptRecord] { attempts.map(\.record) }
}
