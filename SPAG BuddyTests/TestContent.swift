import Foundation
@testable import SPAG_Buddy

enum TestContent {
    /// The repository's content folder, found by walking up from this source file.
    static var directory: URL {
        var url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        while url.path != "/" {
            let candidate = url.appendingPathComponent("SPAG Buddy/Resources/Content")
            if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("manifest.json").path) {
                return candidate
            }
            url.deleteLastPathComponent()
        }
        fatalError("Could not find SPAG Buddy/Resources/Content above \(#filePath)")
    }

    static let library: ContentLibrary = {
        do {
            return try ContentLibrary.load(from: directory)
        } catch {
            fatalError("Content failed to load: \(error)")
        }
    }()

    static func question(
        _ type: QuestionType,
        choices: [String] = [],
        tokens: [String] = [],
        mark: String? = nil,
        answers: [String]
    ) -> Question {
        Question(
            id: "test",
            objectiveCode: "TEST",
            yearGroup: 4,
            strand: .grammar,
            type: type,
            prompt: "Test",
            choices: choices,
            tokens: tokens,
            mark: mark,
            answers: answers,
            explanation: "Because."
        )
    }
}
