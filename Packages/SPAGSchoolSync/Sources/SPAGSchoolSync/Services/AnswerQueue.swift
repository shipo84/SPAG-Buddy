import Foundation

/// Answers waiting to be sent to the teacher, one small file per answer in a folder per pupil.
/// A file is deleted only once the server has confirmed that answer.
///
/// Files can be read once the iPad has been unlocked after a restart, so sending can carry on
/// while the screen is locked.
final class AnswerQueue {
    static let writingOptions: Data.WritingOptions = [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
    static let protection = FileProtectionType.completeUntilFirstUserAuthentication

    static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AnswerQueue", isDirectory: true)
    }

    let directory: URL
    private let fileManager = FileManager.default

    init(directory: URL = AnswerQueue.defaultDirectory) {
        self.directory = directory
    }

    /// Adding the same answer twice keeps one copy, because the file is named after its client id.
    func add(_ upload: AttemptUpload, for pupilId: UUID) throws {
        let folder = folder(for: pupilId)
        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(
                at: folder,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: Self.protection]
            )
        }
        try JSONEncoder.api.encode(upload).write(to: fileURL(upload.clientAttemptId, in: folder), options: Self.writingOptions)
    }

    /// Oldest first.
    func pending(for pupilId: UUID) -> [AttemptUpload] {
        files(for: pupilId)
            .compactMap { try? JSONDecoder.api.decode(AttemptUpload.self, from: Data(contentsOf: $0)) }
            .sorted { $0.answeredAt < $1.answeredAt }
    }

    func count(for pupilId: UUID) -> Int {
        files(for: pupilId).count
    }

    func contains(_ clientAttemptId: UUID, for pupilId: UUID) -> Bool {
        fileManager.fileExists(atPath: fileURL(clientAttemptId, in: folder(for: pupilId)).path)
    }

    func remove(_ clientAttemptIds: Set<UUID>, for pupilId: UUID) {
        let folder = folder(for: pupilId)
        for id in clientAttemptIds {
            try? fileManager.removeItem(at: fileURL(id, in: folder))
        }
    }

    func removeAll(for pupilId: UUID) {
        try? fileManager.removeItem(at: folder(for: pupilId))
    }

    func folder(for pupilId: UUID) -> URL {
        directory.appendingPathComponent(pupilId.uuidString, isDirectory: true)
    }

    private func fileURL(_ clientAttemptId: UUID, in folder: URL) -> URL {
        folder.appendingPathComponent("\(clientAttemptId.uuidString).json")
    }

    private func files(for pupilId: UUID) -> [URL] {
        let contents = (try? fileManager.contentsOfDirectory(at: folder(for: pupilId), includingPropertiesForKeys: nil)) ?? []
        return contents.filter { $0.pathExtension == "json" }
    }
}
