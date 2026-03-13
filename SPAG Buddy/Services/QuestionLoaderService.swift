//
//  QuestionLoaderService.swift
//  SPAG Buddy
//
//  Loads questions from JSON resource files
//

import Foundation

// MARK: - JSON Question Model
struct JSONQuestion: Codable {
    let type: String?
    let question: String?
    let options: [String]?
    let answer: String?
    let explanation: String?

    // Alternative property names for different JSON formats
    let QuestionType: String?
    let Question: String?
    let Options: [String]?
    let Answer: String?
    let Explanation: String?
}

// MARK: - Question Loader Service
class QuestionLoaderService {

    /// Minimum number of answer options required for a question to be answerable
    /// in the multiple-choice quiz UI.
    private static let minimumOptionCount = 2

    // Load questions from JSON file and convert to QuizQuestion format.
    // Only returns questions that have at least 2 options so they are
    // answerable in the multiple-choice quiz view.
    static func loadQuestions(from filename: String) -> [QuizQuestion] {
        let filenames = [filename, filename.replacingOccurrences(of: ".json", with: "")]
        let subpaths = ["", "Punctuation/", "Spelling/", "Grammar/", "Vocabulary/"]

        for subpath in subpaths {
            for name in filenames {
                if let url = Bundle.main.url(forResource: subpath + name, withExtension: "json") {
                    do {
                        let data = try Data(contentsOf: url)

                        // First try to decode as enhanced format
                        if let enhancedBank = try? JSONDecoder().decode(EnhancedQuestionBank.self, from: data) {
                            let questions = enhancedBank.questions
                                .map { $0.toQuizQuestion }
                                .filter { isAnswerable($0) }
                            print("Loaded \(questions.count) answerable enhanced questions from \(subpath)\(name).json")
                            return questions
                        }

                        // Try legacy format
                        let jsonQuestions = try JSONDecoder().decode([JSONQuestion].self, from: data)
                        let questions = convertToQuizQuestions(jsonQuestions)
                        print("Loaded \(questions.count) answerable legacy questions from \(subpath)\(name).json")
                        return questions
                    } catch {
                        print("Error decoding questions from \(subpath)\(name).json: \(error)")
                    }
                }
            }
        }

        print("Could not find JSON file: \(filename) in any expected location")
        return []
    }

    // Load enhanced questions with full metadata.
    // Filters out questions that are not answerable in the MC quiz UI.
    static func loadEnhancedQuestions(from filename: String, pattern: String? = nil) -> [EnhancedSpellingQuestion] {
        let filenames = [filename, filename.replacingOccurrences(of: ".json", with: "")]
        let subpaths = ["", "Punctuation/", "Spelling/", "Grammar/", "Vocabulary/"]

        for subpath in subpaths {
            for name in filenames {
                if let url = Bundle.main.url(forResource: subpath + name, withExtension: "json") {
                    do {
                        let data = try Data(contentsOf: url)

                        // First try to decode as enhanced format
                        if let enhancedBank = try? JSONDecoder().decode(EnhancedQuestionBank.self, from: data) {
                            let filtered = enhancedBank.questions.filter { isEnhancedAnswerable($0) }
                            print("Loaded \(filtered.count) answerable enhanced questions from \(subpath)\(name).json")
                            return filtered
                        }

                        // Try legacy format and convert
                        let jsonQuestions = try JSONDecoder().decode([JSONQuestion].self, from: data)
                        print("Converting legacy questions to enhanced format from \(subpath)\(name).json")

                        let spellingPattern = pattern ?? extractPatternFromFilename(name)
                        let converted: [EnhancedSpellingQuestion] = jsonQuestions.enumerated().compactMap { index, question in
                            LegacyJSONQuestion(
                                type: question.type,
                                question: question.question,
                                options: question.options,
                                answer: question.answer,
                                explanation: question.explanation,
                                QuestionType: question.QuestionType,
                                Question: question.Question,
                                Options: question.Options,
                                Answer: question.Answer,
                                Explanation: question.Explanation
                            ).toEnhancedQuestion(
                                withId: "\(name)_q\(index + 1)",
                                pattern: spellingPattern
                            )
                        }
                        return converted.filter { isEnhancedAnswerable($0) }
                    } catch {
                        print("Error decoding enhanced questions from \(subpath)\(name).json: \(error)")
                    }
                }
            }
        }

        return []
    }

    /// Check whether an enhanced question has enough options to be answerable.
    private static func isEnhancedAnswerable(_ question: EnhancedSpellingQuestion) -> Bool {
        guard question.options.count >= minimumOptionCount else { return false }
        guard !question.question.isEmpty else { return false }
        guard !question.correctAnswers.isEmpty else { return false }
        let hasMatchingAnswer = question.correctAnswers.contains { answer in
            question.options.contains(answer)
        }
        return hasMatchingAnswer
    }

    // MARK: - Answerability Check

    /// A question is answerable in the multiple-choice UI when it has
    /// at least 2 distinct options AND at least one correct answer that
    /// appears in those options.
    private static func isAnswerable(_ question: QuizQuestion) -> Bool {
        guard question.options.count >= minimumOptionCount else { return false }
        guard !question.question.isEmpty else { return false }
        guard !question.correctAnswers.isEmpty else { return false }
        // At least one correct answer must be present in the options
        let hasMatchingAnswer = question.correctAnswers.contains { answer in
            question.options.contains(answer)
        }
        return hasMatchingAnswer
    }

    // MARK: - Legacy Conversion

    /// Convert legacy JSON questions to QuizQuestion format, discarding any
    /// that cannot be answered in a multiple-choice UI.
    private static func convertToQuizQuestions(_ jsonQuestions: [JSONQuestion]) -> [QuizQuestion] {
        return jsonQuestions.compactMap { jsonQuestion in
            let question = jsonQuestion.question ?? jsonQuestion.Question ?? ""
            let options = jsonQuestion.options ?? jsonQuestion.Options ?? []
            let answer = jsonQuestion.answer ?? jsonQuestion.Answer ?? ""
            let explanation = jsonQuestion.explanation ?? jsonQuestion.Explanation ?? ""
            let type = jsonQuestion.type ?? jsonQuestion.QuestionType ?? ""

            guard !question.isEmpty, !answer.isEmpty else { return nil }

            var finalOptions = options
            var correctAnswers = [answer]

            // True/False questions get standard options
            let typeLower = type.lowercased()
            if typeLower.contains("true") || typeLower.contains("false") {
                if finalOptions.isEmpty {
                    finalOptions = ["True", "False"]
                }
            }

            // Handle multi-answer questions
            if question.lowercased().contains("tick two") || answer.contains(" AND ") {
                correctAnswers = answer.components(separatedBy: " AND ").map { $0.trimmingCharacters(in: .whitespaces) }
            }

            let cleanQuestion = question
                .replacingOccurrences(of: #"\(\d+ marks?\)"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let quiz = QuizQuestion(
                cleanQuestion,
                finalOptions,
                correctAnswers,
                explanation.isEmpty ? "Keep practising!" : explanation
            )

            // Only return questions that are answerable in the MC UI
            return isAnswerable(quiz) ? quiz : nil
        }
    }

    // Get questions with fallback to hardcoded ones
    static func getQuestions(for topic: String, fallbackQuestions: [QuizQuestion]) -> [QuizQuestion] {
        let jsonFilename = topic.replacingOccurrences(of: " ", with: "")
        let loadedQuestions = loadQuestions(from: jsonFilename)
        return loadedQuestions.isEmpty ? fallbackQuestions : loadedQuestions
    }

    // Get enhanced questions with filtering options
    static func getEnhancedQuestions(
        for topic: String,
        difficulty: Int? = nil,
        questionTypes: [SpellingQuestionType]? = nil,
        limit: Int? = nil
    ) -> [EnhancedSpellingQuestion] {
        let jsonFilename = topic.replacingOccurrences(of: " ", with: "")
        var questions = loadEnhancedQuestions(from: jsonFilename)

        if let difficulty = difficulty {
            questions = questions.filter { $0.difficulty == difficulty }
        }

        if let types = questionTypes {
            questions = questions.filter { types.contains($0.questionType) }
        }

        questions.shuffle()
        if let limit = limit {
            questions = Array(questions.prefix(limit))
        }

        return questions
    }

    // Helper to extract spelling pattern from filename
    private static func extractPatternFromFilename(_ filename: String) -> String {
        return filename
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
