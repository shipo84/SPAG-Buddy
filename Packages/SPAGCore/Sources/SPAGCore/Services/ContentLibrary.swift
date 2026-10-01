import Foundation

enum ContentError: Error, Equatable {
    case missingFile(String)
    case unknownObjective(questionId: String, objectiveCode: String)
}

/// All curriculum content available to the app: objectives, questions and spelling lists.
public struct ContentLibrary: Sendable {
    public let manifest: ContentManifest
    let objectives: [String: Objective]
    let questions: [Question]
    let spellingLists: [SpellingList]
    public let avatars: [Avatar]

    private let questionsById: [String: Question]

    init(
        manifest: ContentManifest,
        objectives: [Objective],
        questionRecords: [QuestionRecord],
        spellingLists: [SpellingList],
        avatars: [Avatar]
    ) throws {
        self.manifest = manifest
        self.objectives = Dictionary(objectives.map { ($0.code, $0) }, uniquingKeysWith: { first, _ in first })
        self.spellingLists = spellingLists
        self.avatars = avatars

        var built: [Question] = []
        for record in questionRecords {
            guard let objective = self.objectives[record.objectiveCode] else {
                throw ContentError.unknownObjective(questionId: record.id, objectiveCode: record.objectiveCode)
            }
            built.append(Question(record: record, objective: objective))
        }
        for list in spellingLists {
            guard let objective = self.objectives[list.objectiveCode] else {
                throw ContentError.unknownObjective(questionId: list.id, objectiveCode: list.objectiveCode)
            }
            built.append(contentsOf: SpellingQuestionFactory.questions(for: list, objective: objective))
        }
        questions = built
        questionsById = Dictionary(built.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Loads content from a folder containing `manifest.json` and the files it lists.
    public static func load(from directory: URL) throws -> ContentLibrary {
        try load { name in
            let url = directory.appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: url.path) else { throw ContentError.missingFile(name) }
            return try Data(contentsOf: url)
        }
    }

    /// Loads the content shipped with SPAGCore.
    public static func loadBundled() throws -> ContentLibrary {
        try loadBundled(from: .module)
    }

    static func loadBundled(from bundle: Bundle) throws -> ContentLibrary {
        try load { name in
            let base = (name as NSString).deletingPathExtension
            let ext = (name as NSString).pathExtension
            let url = bundle.url(forResource: base, withExtension: ext)
                ?? bundle.url(forResource: base, withExtension: ext, subdirectory: "Content")
                ?? bundle.url(forResource: base, withExtension: ext, subdirectory: "Resources/Content")
            guard let url else { throw ContentError.missingFile(name) }
            return try Data(contentsOf: url)
        }
    }

    static func load(readFile: (String) throws -> Data) throws -> ContentLibrary {
        let decoder = JSONDecoder()
        let manifest = try decoder.decode(ContentManifest.self, from: readFile("manifest.json"))
        let objectives = try decoder.decode(ObjectivesFile.self, from: readFile(manifest.objectivesFile)).objectives
        let lists = try decoder.decode(SpellingListsFile.self, from: readFile(manifest.spellingListsFile)).lists
        let avatars = try decoder.decode(AvatarsFile.self, from: readFile(manifest.avatarsFile)).avatars
        var records: [QuestionRecord] = []
        for file in manifest.questionFiles {
            records.append(contentsOf: try decoder.decode(QuestionBankFile.self, from: readFile(file)).questions)
        }
        return try ContentLibrary(
            manifest: manifest,
            objectives: objectives,
            questionRecords: records,
            spellingLists: lists,
            avatars: avatars
        )
    }

    func question(id: String) -> Question? { questionsById[id] }

    func objective(code: String) -> Objective? { objectives[code] }

    public func avatar(key: String) -> Avatar? { avatars.first { $0.key == key } }

    func questions(forYears years: ClosedRange<Int>) -> [Question] {
        questions.filter { years.contains($0.yearGroup) || isSpellingQuestion($0, forAnyOf: years) }
    }

    func objectives(forYear year: Int) -> [Objective] {
        objectives.values.filter { $0.yearGroup == year }.sorted { $0.code < $1.code }
    }

    func spellingLists(forYear year: Int) -> [SpellingList] {
        spellingLists.filter { $0.yearGroups.contains(year) }
    }

    func spellingList(id: String) -> SpellingList? { spellingLists.first { $0.id == id } }

    private func isSpellingQuestion(_ question: Question, forAnyOf years: ClosedRange<Int>) -> Bool {
        guard question.type == .spelling,
              let list = spellingLists.first(where: { $0.objectiveCode == question.objectiveCode }) else { return false }
        return list.yearGroups.contains { years.contains($0) }
    }
}

enum SpellingQuestionFactory {
    /// Must match `spellingQuestionId` in `backend/scripts/generate-seed.mjs`.
    static func questionId(listId: String, word: String) -> String {
        "spell-\(listId)-\(slug(word))"
    }

    static func slug(_ text: String) -> String {
        var result = ""
        var lastWasDash = false
        for scalar in text.lowercased().unicodeScalars {
            if ("a"..."z").contains(scalar) || ("0"..."9").contains(scalar) {
                result.unicodeScalars.append(scalar)
                lastWasDash = false
            } else if !lastWasDash && !result.isEmpty {
                result.append("-")
                lastWasDash = true
            }
        }
        while result.hasSuffix("-") { result.removeLast() }
        return result
    }

    static func questions(for list: SpellingList, objective: Objective) -> [Question] {
        list.words.map { entry in
            let spoken = entry.sentence.map { "\(entry.word). \($0) \(entry.word)." } ?? "\(entry.word)."
            let letters = entry.word.map(String.init).joined(separator: " - ")
            return Question(
                id: questionId(listId: list.id, word: entry.word),
                objectiveCode: list.objectiveCode,
                yearGroup: objective.yearGroup,
                strand: .spelling,
                type: .spelling,
                prompt: "Listen, then spell the word.",
                answers: [entry.word],
                explanation: "It is spelled \(letters).",
                audioText: spoken
            )
        }
    }
}
