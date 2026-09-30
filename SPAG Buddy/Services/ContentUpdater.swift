import Foundation

/// Downloads newer question banks published by the backend so content can change without an App Store release.
enum ContentUpdater {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Content", isDirectory: true)
    }

    /// Downloaded content, if it is valid and newer than the content inside the app.
    static func loadDownloadedContent(newerThan bundledVersion: String?) -> ContentLibrary? {
        guard let library = try? ContentLibrary.load(from: directory) else { return nil }
        if let bundledVersion, !ContentVersion.isNewer(library.manifest.contentVersion, than: bundledVersion) {
            return nil
        }
        return library
    }

    /// Returns the new library when an update was installed.
    static func update(using api: APIClient, currentVersion: String) async -> ContentLibrary? {
        guard let manifest = try? await api.contentManifest(),
              !manifest.files.isEmpty,
              ContentVersion.isNewer(manifest.contentVersion, than: currentVersion) else { return nil }

        let fileManager = FileManager.default
        let staging = fileManager.temporaryDirectory.appendingPathComponent("content-\(UUID().uuidString)", isDirectory: true)
        do {
            try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
            defer { try? fileManager.removeItem(at: staging) }
            for file in manifest.files {
                guard !file.name.contains("/") else { return nil }
                try await api.download(file.url).write(to: staging.appendingPathComponent(file.name))
            }
            // Only install content that loads and validates completely.
            let library = try ContentLibrary.load(from: staging)
            try? fileManager.removeItem(at: directory)
            try fileManager.createDirectory(at: directory.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fileManager.copyItem(at: staging, to: directory)
            return library
        } catch {
            return nil
        }
    }
}
