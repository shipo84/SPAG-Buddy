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

    // Load questions from JSON file and convert to QuizQuestion format
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
                            print("Successfully loaded enhanced questions from \(subpath)\(name).json")
                            return enhancedBank.questions.map { $0.toQuizQuestion }
                        }

                        // Try legacy format
                        let jsonQuestions = try JSONDecoder().decode([JSONQuestion].self, from: data)
                        print("Successfully loaded legacy questions from \(subpath)\(name).json")
                        return convertToQuizQuestions(jsonQuestions)
                    } catch {
                        print("Error decoding questions from \(subpath)\(name).json: \(error)")
                    }
                }
            }
        }

        print("Could not find JSON file: \(filename) in any expected location")
        return []
    }

    // Load enhanced questions with full metadata
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
                            print("Successfully loaded enhanced questions from \(subpath)\(name).json")
                            return enhancedBank.questions
                        }

                        // Try legacy format and convert
                        let jsonQuestions = try JSONDecoder().decode([JSONQuestion].self, from: data)
                        print("Converting legacy questions to enhanced format from \(subpath)\(name).json")

                        let spellingPattern = pattern ?? extractPatternFromFilename(name)
                        return jsonQuestions.enumerated().compactMap { index, question in
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
                    } catch {
                        print("Error decoding enhanced questions from \(subpath)\(name).json: \(error)")
                    }
                }
            }
        }

        return []
    }

    // Convert JSON questions to the app's QuizQuestion format
    private static func convertToQuizQuestions(_ jsonQuestions: [JSONQuestion]) -> [QuizQuestion] {
        return jsonQuestions.compactMap { jsonQuestion in
            let question = jsonQuestion.question ?? jsonQuestion.Question ?? ""
            let options = jsonQuestion.options ?? jsonQuestion.Options ?? []
            let answer = jsonQuestion.answer ?? jsonQuestion.Answer ?? ""
            let explanation = jsonQuestion.explanation ?? jsonQuestion.Explanation ?? ""
            let type = jsonQuestion.type ?? jsonQuestion.QuestionType ?? ""

            guard !question.isEmpty && !answer.isEmpty else { return nil }

            var finalOptions = options
            var correctAnswers = [answer]

            if type.lowercased().contains("true") || type.lowercased().contains("false") {
                if finalOptions.isEmpty {
                    finalOptions = ["True", "False"]
                }
            }

            if question.lowercased().contains("tick two") || answer.contains(" AND ") {
                correctAnswers = answer.components(separatedBy: " AND ").map { $0.trimmingCharacters(in: .whitespaces) }
            } else if answer.contains(" / ") {
                correctAnswers = [answer]
            }

            let cleanQuestion = question
                .replacingOccurrences(of: #"\(\d+ marks?\)"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if finalOptions.isEmpty && !type.lowercased().contains("true") && !type.lowercased().contains("false") {
                finalOptions = correctAnswers
            }

            return QuizQuestion(
                cleanQuestion,
                finalOptions,
                correctAnswers,
                explanation.isEmpty ? "Keep practicing!" : explanation
            )
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
