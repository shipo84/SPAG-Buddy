import Foundation
import SPAGCore

enum TestContent {
    /// SPAGCore's content folder, found by walking up from this source file.
    static var directory: URL {
        var url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        while url.path != "/" {
            let candidate = url.appendingPathComponent("SPAGCore/Sources/SPAGCore/Resources/Content")
            if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("manifest.json").path) {
                return candidate
            }
            url.deleteLastPathComponent()
        }
        fatalError("Could not find SPAGCore/Sources/SPAGCore/Resources/Content above \(#filePath)")
    }

    static let library: ContentLibrary = {
        do {
            return try ContentLibrary.load(from: directory)
        } catch {
            fatalError("Content failed to load: \(error)")
        }
    }()
}
