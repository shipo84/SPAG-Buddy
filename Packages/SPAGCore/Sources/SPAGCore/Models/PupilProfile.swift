import Foundation
import SwiftData

@Model
public final class PupilProfile {
    @Attribute(.unique) public var id: UUID
    /// First name or nickname only.
    public var displayName: String
    public var avatarKey: String
    public var yearGroup: Int
    public var createdAt: Date

    /// Set when the pupil has joined a class. `nil` means home practice only, and nothing is uploaded.
    public var remotePupilId: String?
    public var classCode: String?
    public var className: String?
    public var lastSyncedAt: Date?

    public var easyReadText: Bool
    public var highContrast: Bool
    public var autoReadAloud: Bool

    public var stars: Int
    public var currentStreak: Int
    public var longestStreak: Int
    public var lastPracticeDay: Date?
    public var sessionsCompleted: Int
    public var satsSessionsCompleted: Int

    @Relationship(deleteRule: .cascade, inverse: \Attempt.pupil)
    public var attempts: [Attempt] = []

    @Relationship(deleteRule: .cascade, inverse: \BadgeProgress.pupil)
    public var badges: [BadgeProgress] = []

    @Relationship(deleteRule: .cascade, inverse: \Assignment.pupil)
    public var assignments: [Assignment] = []

    public init(
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

    public var isInClass: Bool { remotePupilId != nil }

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
