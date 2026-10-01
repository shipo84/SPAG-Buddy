import Foundation
import SwiftData

/// Work set by the teacher on the website, downloaded for each pupil in the class.
@Model
public final class Assignment {
    public var remoteId: String
    public var pupil: PupilProfile?
    public var title: String
    public var objectiveCodes: [String]
    public var spellingListId: String?
    public var dueDate: Date?
    public var completedAt: Date?
    public var fetchedAt: Date

    public init(
        remoteId: String,
        pupil: PupilProfile,
        title: String,
        objectiveCodes: [String],
        spellingListId: String?,
        dueDate: Date?
    ) {
        self.remoteId = remoteId
        self.pupil = pupil
        self.title = title
        self.objectiveCodes = objectiveCodes
        self.spellingListId = spellingListId
        self.dueDate = dueDate
        self.fetchedAt = .now
    }

    var mode: SessionMode {
        .assignment(id: remoteId, objectiveCodes: objectiveCodes, spellingListId: spellingListId)
    }
}
