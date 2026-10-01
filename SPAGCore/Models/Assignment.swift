import Foundation
import SwiftData

/// Work set by the teacher on the website, downloaded for each pupil in the class.
@Model
final class Assignment {
    var remoteId: String
    var pupil: PupilProfile?
    var title: String
    var objectiveCodes: [String]
    var spellingListId: String?
    var dueDate: Date?
    var completedAt: Date?
    var fetchedAt: Date

    init(
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
