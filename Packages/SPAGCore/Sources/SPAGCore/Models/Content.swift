import Foundation

enum Strand: String, Codable, CaseIterable, Identifiable, Sendable {
    case spelling
    case punctuation
    case grammar
    case vocabulary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spelling: "Spelling"
        case .punctuation: "Punctuation"
        case .grammar: "Grammar"
        case .vocabulary: "Words"
        }
    }

    var symbolName: String {
        switch self {
        case .spelling: "character.book.closed.fill"
        case .punctuation: "exclamationmark.bubble.fill"
        case .grammar: "puzzlepiece.fill"
        case .vocabulary: "textformat.abc"
        }
    }
}

enum QuestionType: String, Codable, Sendable {
    /// Tick one.
    case multipleChoice
    /// Tick or circle all that apply.
    case multiSelect
    /// Listen to a word and type it.
    case spelling
    /// Tap the gap (or gaps) where a punctuation mark belongs.
    case tapGap
    /// Type a rewritten word or sentence.
    case rewrite
}

struct Objective: Codable, Hashable, Identifiable, Sendable {
    var code: String
    var yearGroup: Int
    var strand: Strand
    /// Teacher-facing title using National Curriculum terminology.
    var title: String
    /// Short title a child can read.
    var childTitle: String
    /// One-line rule shown as a hint and in feedback.
    var rule: String

    var id: String { code }
}

/// A question exactly as it appears in a `yearN.json` file.
struct QuestionRecord: Codable, Hashable, Sendable {
    var id: String
    var objectiveCode: String
    var type: QuestionType
    var prompt: String
    /// Word or phrase in the prompt to underline, e.g. the word whose class is being asked about.
    var highlight: String?
    var choices: [String]?
    /// Words of the sentence for `tapGap` questions.
    var tokens: [String]?
    /// The punctuation mark to insert for `tapGap` questions.
    var mark: String?
    /// Accepted answers. For `tapGap` these are gap indexes, where gap `i` follows `tokens[i]`.
    var answers: [String]
    var explanation: String
    /// What the read-aloud button says. Defaults to the prompt.
    var audioText: String?
    var satsStyle: Bool?
}

struct Question: Hashable, Identifiable, Sendable {
    var id: String
    var objectiveCode: String
    var yearGroup: Int
    var strand: Strand
    var type: QuestionType
    var prompt: String
    var highlight: String?
    var choices: [String]
    var tokens: [String]
    var mark: String?
    var answers: [String]
    var explanation: String
    var audioText: String
    var satsStyle: Bool

    init(record: QuestionRecord, objective: Objective) {
        id = record.id
        objectiveCode = record.objectiveCode
        yearGroup = objective.yearGroup
        strand = objective.strand
        type = record.type
        prompt = record.prompt
        highlight = record.highlight
        choices = record.choices ?? []
        tokens = record.tokens ?? []
        mark = record.mark
        answers = record.answers
        explanation = record.explanation
        audioText = record.audioText ?? record.prompt
        satsStyle = record.satsStyle ?? false
    }

    init(
        id: String,
        objectiveCode: String,
        yearGroup: Int,
        strand: Strand,
        type: QuestionType,
        prompt: String,
        highlight: String? = nil,
        choices: [String] = [],
        tokens: [String] = [],
        mark: String? = nil,
        answers: [String],
        explanation: String,
        audioText: String? = nil,
        satsStyle: Bool = false
    ) {
        self.id = id
        self.objectiveCode = objectiveCode
        self.yearGroup = yearGroup
        self.strand = strand
        self.type = type
        self.prompt = prompt
        self.highlight = highlight
        self.choices = choices
        self.tokens = tokens
        self.mark = mark
        self.answers = answers
        self.explanation = explanation
        self.audioText = audioText ?? prompt
        self.satsStyle = satsStyle
    }

    var gapAnswers: Set<Int> { Set(answers.compactMap(Int.init)) }
}

struct SpellingWord: Codable, Hashable, Sendable {
    var word: String
    /// Read after the word when it sounds like another word (e.g. "reign", "our").
    var sentence: String?
}

struct SpellingList: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var title: String
    var objectiveCode: String
    var yearGroups: [Int]
    var words: [SpellingWord]
}

struct QuestionBankFile: Codable, Sendable {
    var yearGroup: Int
    var questions: [QuestionRecord]
}

struct ObjectivesFile: Codable, Sendable {
    var objectives: [Objective]
}

struct SpellingListsFile: Codable, Sendable {
    var lists: [SpellingList]
}

public struct Avatar: Codable, Hashable, Identifiable, Sendable {
    var key: String
    var emoji: String
    var name: String

    public var id: String { key }
}

struct AvatarsFile: Codable, Sendable {
    var avatars: [Avatar]
}

public struct ContentManifest: Codable, Sendable {
    var schemaVersion: Int
    public var contentVersion: String
    var objectivesFile: String
    var spellingListsFile: String
    var avatarsFile: String
    var questionFiles: [String]
}
