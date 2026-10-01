import Foundation
import SwiftData

@Model
public final class BadgeProgress {
    public var badgeId: String
    public var earnedAt: Date
    public var pupil: PupilProfile?

    init(badgeId: String, pupil: PupilProfile, earnedAt: Date = .now) {
        self.badgeId = badgeId
        self.pupil = pupil
        self.earnedAt = earnedAt
    }

    var badge: Badge? { BadgeRules.badge(id: badgeId) }
}
