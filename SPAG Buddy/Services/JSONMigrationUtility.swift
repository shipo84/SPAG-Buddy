//
//  JSONMigrationUtility.swift
//  SPAG Buddy
//
//  Utility for migrating legacy JSON question formats to enhanced format
//

import Foundation

class JSONMigrationUtility {

    // Convert a legacy JSON file to enhanced format
    static func migrateJSONFile(filename: String, spellingPattern: String, yearGroups: [Int] = [5, 6]) -> Bool {
        let questions = QuestionLoaderService.loadQuestions(from: filename)

        guard !questions.isEmpty else {
            print("No questions found in \(filename)")
            return false
        }

        let enhancedQuestions = questions.enumerated().compactMap { index, question in
            let legacyQuestion = LegacyJSONQuestion(
                type: "multiple_choice",
                question: question.question,
                options: question.options,
                answer: question.correctAnswers.joined(separator: " AND "),
                explanation: question.explanation,
                QuestionType: nil,
                Question: nil,
                Options: nil,
                Answer: nil,
                Explanation: nil
            )

            return legacyQuestion.toEnhancedQuestion(
                withId: "\(filename)_q\(index + 1)",
                pattern: spellingPattern
            )
        }

        let enhancedBank = EnhancedQuestionBank(
            metadata: EnhancedQuestionBank.QuestionBankMetadata(
                topic: formatTopicName(filename),
                yearGroups: yearGroups,
                lastUpdated: ISO8601DateFormatter().string(from: Date()),
                totalQuestions: enhancedQuestions.count,
                difficultyDistribution: calculateDifficultyDistribution(enhancedQuestions)
            ),
            questions: enhancedQuestions
        )

        return saveEnhancedBank(enhancedBank, filename: "\(filename)_Enhanced")
    }

    // Batch migrate all spelling JSON files
    static func migrateAllSpellingFiles() {
        let spellingFiles = [
            ("Homophones", "homophones"),
            ("SilentLetters", "silent_letters"),
            ("Prefixes", "prefixes"),
            ("Suffixes", "suffixes"),
            ("VowelDigraphsTrigraphs", "vowel_digraphs"),
            ("SoftCSoftG", "soft_c_soft_g"),
            ("Hyphens-2", "hyphens"),
            ("DroppingSilentE", "dropping_silent_e"),
            ("ConsonantDoublingRules", "consonant_doubling"),
            ("ChangingYtoI", "changing_y_to_i")
        ]

        for (filename, pattern) in spellingFiles {
            print("Migrating \(filename)...")
            if migrateJSONFile(filename: filename, spellingPattern: pattern) {
                print("Successfully migrated \(filename)")
            } else {
                print("Failed to migrate \(filename)")
            }
        }
    }

    // Helper functions
    private static func formatTopicName(_ filename: String) -> String {
        return filename
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { word in
                word.prefix(1).uppercased() + word.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }

    private static func calculateDifficultyDistribution(_ questions: [EnhancedSpellingQuestion]) -> [String: Int] {
        var distribution: [String: Int] = [:]

        for question in questions {
            let key = String(question.difficulty)
            distribution[key, default: 0] += 1
        }

        return distribution
    }

    private static func saveEnhancedBank(_ bank: EnhancedQuestionBank, filename: String) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(bank)

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsPath.appendingPathComponent("\(filename).json")

            try data.write(to: fileURL)
            print("Saved enhanced JSON to: \(fileURL.path)")
            return true
        } catch {
            print("Error saving enhanced JSON: \(error)")
            return false
        }
    }
}

// Extension for migration report
extension JSONMigrationUtility {
    static func generateMigrationReport() -> String {
        var report = "JSON Migration Report\n"
        report += "====================\n\n"

        let resourcePath = Bundle.main.resourcePath ?? ""
        let spellingPath = "\(resourcePath)/Spelling"

        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: spellingPath)
            let jsonFiles = files.filter { $0.hasSuffix(".json") && !$0.contains("Enhanced") }

            report += "Found \(jsonFiles.count) legacy JSON files in Spelling folder:\n"
            for file in jsonFiles {
                report += "- \(file)\n"
            }

            report += "\nTo migrate all files, call JSONMigrationUtility.migrateAllSpellingFiles()\n"
        } catch {
            report += "Error accessing Spelling resources: \(error)\n"
        }

        return report
    }
}
