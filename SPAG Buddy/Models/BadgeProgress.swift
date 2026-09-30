import Foundation
import SwiftData

@Model
final class BadgeProgress {
    var badgeId: String
    var earnedAt: Date
    var pupil: PupilProfile?

    init(badgeId: String, pupil: PupilProfile, earnedAt: Date = .now) {
        self.badgeId = badgeId
        self.pupil = pupil
        self.earnedAt = earnedAt
    }

    var badge: Badge? { BadgeRules.badge(id: badgeId) }
}
