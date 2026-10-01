import Foundation

enum SessionMode: Hashable, Sendable {
    /// Mixed practice weighted towards the pupil's weaker objectives.
    case daily
    case strand(Strand)
    case objective(String)
    case spellingList(String)
    case assignment(id: String, objectiveCodes: [String], spellingListId: String?)
    /// Year 6 GPS-style mini paper. Answers are only revealed at the end.
    case satsPractice

    /// Sent to the server with each attempt.
    var kind: String {
        switch self {
        case .daily: "daily"
        case .strand: "strand"
        case .objective: "objective"
        case .spellingList: "spelling-list"
        case .assignment: "assignment"
        case .satsPractice: "sats"
        }
    }

    var givesInstantFeedback: Bool { self != .satsPractice }

    var assignmentId: String? {
        if case .assignment(let id, _, _) = self { return id }
        return nil
    }

    var defaultLength: Int {
        switch self {
        case .daily, .strand: 8
        case .objective: 6
        case .spellingList, .assignment, .satsPractice: 10
        }
    }
}

struct SessionBuilder: Sendable {
    let library: ContentLibrary

    func build(
        mode: SessionMode,
        yearGroup: Int,
        stats: [String: ObjectiveStats],
        recentQuestionIds: Set<String> = [],
        length: Int? = nil,
        using rng: inout some RandomNumberGenerator
    ) -> [Question] {
        let count = length ?? mode.defaultLength
        let reviewYears = max(1, yearGroup - 1)...max(1, yearGroup)
        let pool: [Question]
        var weighted = true

        switch mode {
        case .daily:
            pool = library.questions(forYears: reviewYears).filter { !$0.satsStyle || yearGroup >= 5 }
        case .strand(let strand):
            pool = library.questions(forYears: reviewYears).filter { $0.strand == strand }
        case .objective(let code):
            pool = library.questions.filter { $0.objectiveCode == code }
            weighted = false
        case .spellingList(let listId):
            pool = spellingQuestions(listId: listId)
            weighted = false
        case .assignment(_, let codes, let listId):
            let codeSet = Set(codes)
            pool = library.questions.filter { codeSet.contains($0.objectiveCode) && $0.type != .spelling }
                + (listId.map(spellingQuestions(listId:)) ?? [])
            weighted = false
        case .satsPractice:
            pool = library.questions.filter { $0.satsStyle && $0.yearGroup <= max(yearGroup, 6) }
            weighted = false
        }

        return pick(from: pool, count: count, stats: stats, recent: recentQuestionIds, weighted: weighted, rng: &rng)
    }

    private func spellingQuestions(listId: String) -> [Question] {
        let prefix = "spell-\(listId)-"
        return library.questions.filter { $0.id.hasPrefix(prefix) }
    }

    /// Picks an objective first, then a question within it, so large spelling lists do not crowd out grammar.
    private func pick(
        from pool: [Question],
        count: Int,
        stats: [String: ObjectiveStats],
        recent: Set<String>,
        weighted: Bool,
        rng: inout some RandomNumberGenerator
    ) -> [Question] {
        var byObjective = Dictionary(grouping: pool, by: \.objectiveCode)
        for key in byObjective.keys {
            byObjective[key]?.shuffle(using: &rng)
            byObjective[key]?.sort { !recent.contains($0.id) && recent.contains($1.id) }
        }
        let maxPerObjective = max(3, Int((Double(count) / Double(max(byObjective.count, 1))).rounded(.up)))
        var usedPerObjective: [String: Int] = [:]
        var chosen: [Question] = []

        while chosen.count < count {
            let candidates = byObjective
                .filter { !$0.value.isEmpty && usedPerObjective[$0.key, default: 0] < maxPerObjective }
                .keys
                .sorted()
            guard !candidates.isEmpty else { break }

            let weights = candidates.map { code in weighted ? weight(for: stats[code]) : 1 }
            let objective = candidates[weightedIndex(weights, rng: &rng)]
            if let question = byObjective[objective]?.removeFirst() {
                chosen.append(question)
                usedPerObjective[objective, default: 0] += 1
            }
        }
        return chosen.shuffled(using: &rng)
    }

    private func weight(for stats: ObjectiveStats?) -> Double {
        switch stats?.level ?? .notStarted {
        case .needsSupport: 3
        case .notStarted, .developing: 2
        case .secure: 0.5
        }
    }

    private func weightedIndex(_ weights: [Double], rng: inout some RandomNumberGenerator) -> Int {
        let total = weights.reduce(0, +)
        var target = Double.random(in: 0..<total, using: &rng)
        for (index, weight) in weights.enumerated() {
            target -= weight
            if target < 0 { return index }
        }
        return weights.count - 1
    }
}

/// Deterministic generator for tests and previews.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
