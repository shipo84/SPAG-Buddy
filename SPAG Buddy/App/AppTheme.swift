//
//  AppTheme.swift
//  SPAG Buddy
//
//  Centralised theme and styling for consistent look and feel
//

import SwiftUI

// MARK: - App Theme
struct AppTheme {
    // MARK: - Colours
    struct Colors {
        // Primary background - warm cream
        static let background = Color(red: 255/255, green: 248/255, blue: 231/255)
        // Slightly darker cream for subtle contrast
        static let backgroundSecondary = Color(red: 250/255, green: 242/255, blue: 220/255)
        // Card background
        static let cardBackground = Color.white
        // Primary accent - friendly blue
        static let accent = Color(red: 66/255, green: 133/255, blue: 244/255)
        // Secondary accent - teal
        static let accentSecondary = Color(red: 38/255, green: 166/255, blue: 154/255)

        // Category colours
        static let spelling = Color(red: 66/255, green: 133/255, blue: 244/255)       // Blue
        static let punctuation = Color(red: 76/255, green: 175/255, blue: 80/255)      // Green
        static let grammar = Color(red: 156/255, green: 39/255, blue: 176/255)         // Purple
        static let vocabulary = Color(red: 255/255, green: 152/255, blue: 0/255)        // Orange

        // Semantic colours
        static let correct = Color(red: 76/255, green: 175/255, blue: 80/255)
        static let incorrect = Color(red: 244/255, green: 67/255, blue: 54/255)
        static let warning = Color(red: 255/255, green: 193/255, blue: 7/255)
        static let xp = Color(red: 255/255, green: 193/255, blue: 7/255)
        static let streak = Color(red: 255/255, green: 87/255, blue: 34/255)

        // Text colours
        static let textPrimary = Color(red: 33/255, green: 33/255, blue: 33/255)
        static let textSecondary = Color(red: 117/255, green: 117/255, blue: 117/255)
        static let textTertiary = Color(red: 158/255, green: 158/255, blue: 158/255)
    }

    // MARK: - Gradients
    struct Gradients {
        static let dailyChallenge = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 66/255, green: 133/255, blue: 244/255),
                Color(red: 156/255, green: 39/255, blue: 176/255)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let testOfTheDay = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 38/255, green: 166/255, blue: 154/255),
                Color(red: 0/255, green: 137/255, blue: 123/255)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let xpBar = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 66/255, green: 133/255, blue: 244/255),
                Color(red: 156/255, green: 39/255, blue: 176/255)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Dimensions
    struct Dimensions {
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 16
        static let cornerRadiusXLarge: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 20
        static let itemSpacing: CGFloat = 12
    }
}

// MARK: - Card Modifier
struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.Dimensions.cornerRadiusLarge
    var shadowRadius: CGFloat = 3

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Dimensions.cardPadding)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.06), radius: shadowRadius, x: 0, y: 2)
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = AppTheme.Colors.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .cornerRadius(AppTheme.Dimensions.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle(cornerRadius: CGFloat = AppTheme.Dimensions.cornerRadiusLarge, shadowRadius: CGFloat = 3) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}

// MARK: - SPAG Category Model
enum SPAGCategory: String, CaseIterable, Identifiable {
    case spelling = "Spelling"
    case punctuation = "Punctuation"
    case grammar = "Grammar"
    case vocabulary = "Vocabulary"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .spelling: return "textformat.abc"
        case .punctuation: return "pencil.circle.fill"
        case .grammar: return "text.book.closed.fill"
        case .vocabulary: return "character.book.closed.fill"
        }
    }

    var color: Color {
        switch self {
        case .spelling: return AppTheme.Colors.spelling
        case .punctuation: return AppTheme.Colors.punctuation
        case .grammar: return AppTheme.Colors.grammar
        case .vocabulary: return AppTheme.Colors.vocabulary
        }
    }

    var description: String {
        switch self {
        case .spelling: return "Master tricky words and spelling rules"
        case .punctuation: return "Perfect your punctuation skills"
        case .grammar: return "Understand sentence structure"
        case .vocabulary: return "Expand your word knowledge"
        }
    }

    var topics: [SPAGTopic] {
        switch self {
        case .spelling:
            return [
                SPAGTopic(name: "Homophones", filename: "Homophones_Enhanced", questionCount: 30),
                SPAGTopic(name: "Silent Letters", filename: "SilentLetters", questionCount: 20),
                SPAGTopic(name: "Prefixes", filename: "SpellingRules", questionCount: 25),
                SPAGTopic(name: "Suffixes", filename: "SpellingRules", questionCount: 25),
                SPAGTopic(name: "Dropping Silent E", filename: "DroppingSilentE", questionCount: 15),
                SPAGTopic(name: "Soft C and Soft G", filename: "SoftCSoftG", questionCount: 15),
                SPAGTopic(name: "Vowel Digraphs", filename: "VowelDigraphsTrigraphs", questionCount: 20),
                SPAGTopic(name: "Consonant Doubling", filename: "ConsonantDoublingRules", questionCount: 15),
                SPAGTopic(name: "Changing Y to I", filename: "ChangingYtoI", questionCount: 15),
                SPAGTopic(name: "Hyphens in Spelling", filename: "Hyphens", questionCount: 15)
            ]
        case .punctuation:
            return [
                SPAGTopic(name: "Apostrophes", filename: "Apostrophes", questionCount: 20),
                SPAGTopic(name: "Commas in Lists", filename: "CommasInLists", questionCount: 20),
                SPAGTopic(name: "Inverted Commas", filename: "InvertedCommas", questionCount: 20),
                SPAGTopic(name: "Colons & Semicolons", filename: "ColonsSemicolons", questionCount: 20),
                SPAGTopic(name: "Full Stops", filename: "FullStops", questionCount: 15),
                SPAGTopic(name: "Question Marks", filename: "QuestionMarks", questionCount: 15),
                SPAGTopic(name: "Exclamation Marks", filename: "ExclamationMarks", questionCount: 15),
                SPAGTopic(name: "Capital Letters", filename: "CapitalLetters", questionCount: 15),
                SPAGTopic(name: "Brackets & Dashes", filename: "DashesAndEllipsis", questionCount: 15),
                SPAGTopic(name: "Paragraphs", filename: "Paragraphs", questionCount: 15)
            ]
        case .grammar:
            return [
                SPAGTopic(name: "Adjectives", filename: "Adjectives", questionCount: 20),
                SPAGTopic(name: "Adjective Prefixes", filename: "AdjectivePrefixes", questionCount: 15),
                SPAGTopic(name: "Adverbs & Adverbials", filename: "Adverbs", questionCount: 20),
                SPAGTopic(name: "Clauses", filename: "Clauses", questionCount: 20),
                SPAGTopic(name: "Nouns & Noun Phrases", filename: "Adjectives", questionCount: 20),
                SPAGTopic(name: "Verbs & Tenses", filename: "Adverbs", questionCount: 20),
                SPAGTopic(name: "Conjunctions", filename: "Clauses", questionCount: 15),
                SPAGTopic(name: "Prepositions", filename: "Adverbs", questionCount: 15),
                SPAGTopic(name: "Active & Passive Voice", filename: "Clauses", questionCount: 15),
                SPAGTopic(name: "Sentence Types", filename: "Adjectives", questionCount: 15)
            ]
        case .vocabulary:
            return [
                SPAGTopic(name: "Synonyms & Antonyms", filename: "SynonymsAndAntonyms", questionCount: 20),
                SPAGTopic(name: "Root Words", filename: "RootWordsAndWordFamilies", questionCount: 20),
                SPAGTopic(name: "Prefixes", filename: "Prefixes", questionCount: 20),
                SPAGTopic(name: "Suffixes", filename: "Suffixes", questionCount: 20),
                SPAGTopic(name: "Homophones", filename: "Homophones", questionCount: 20),
                SPAGTopic(name: "Word Families", filename: "RootWordsAndWordFamilies", questionCount: 15),
                SPAGTopic(name: "Formal & Informal", filename: "SynonymsAndAntonyms", questionCount: 15),
                SPAGTopic(name: "Word Origins", filename: "RootWordsAndWordFamilies", questionCount: 15)
            ]
        }
    }
}

// MARK: - SPAG Topic
struct SPAGTopic: Identifiable {
    let id = UUID()
    let name: String
    let filename: String
    let questionCount: Int
}
