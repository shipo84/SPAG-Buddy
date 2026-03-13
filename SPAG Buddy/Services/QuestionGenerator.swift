//
//  QuestionGenerator.swift
//  SPAG Buddy
//
//  Fallback question generation when JSON resources are unavailable
//

import Combine
import Foundation

// MARK: - Question Generator Service
class QuestionGenerator: ObservableObject {

    /// Built-in question bank used as a fallback when JSON files cannot be loaded.
    private static let fallbackBank: [QuizQuestion] = [
        // Spelling
        QuizQuestion("Which word is spelled correctly?", ["recieve", "receive", "receve", "receeve"], ["receive"], "'i' before 'e' except after 'c'. The correct spelling is 'receive'."),
        QuizQuestion("Which word is spelled correctly?", ["seperate", "separete", "separate", "seperete"], ["separate"], "Remember: there is 'a rat' in separate!"),
        QuizQuestion("Which word is spelled correctly?", ["definately", "definatley", "definitely", "defintely"], ["definitely"], "The word 'definitely' contains 'finite'."),
        QuizQuestion("Choose the correct spelling:", ["neccessary", "necessary", "neccesary", "necessery"], ["necessary"], "One 'c' and two 's's: necessary. Think: one collar and two socks."),
        QuizQuestion("Which word is spelled correctly?", ["occassion", "occasion", "ocassion", "ocasion"], ["occasion"], "Two 'c's and one 's': occasion."),

        // Punctuation
        QuizQuestion("Which sentence uses an apostrophe correctly?", ["The dog's bowl is empty.", "The dogs' bowl is empty.", "The dog bowl's is empty.", "The dogs bowl is empty."], ["The dog's bowl is empty."], "Use an apostrophe + s to show that the bowl belongs to one dog."),
        QuizQuestion("Which sentence uses commas correctly?", ["I bought apples oranges and bananas.", "I bought apples, oranges, and bananas.", "I bought, apples oranges and bananas.", "I bought apples oranges, and bananas."], ["I bought apples, oranges, and bananas."], "Use commas to separate items in a list."),
        QuizQuestion("Which sentence is punctuated correctly?", ["Its a lovely day.", "It's a lovely day.", "Its' a lovely day.", "It,s a lovely day."], ["It's a lovely day."], "'It's' with an apostrophe means 'it is'. 'Its' without an apostrophe means 'belonging to it'."),
        QuizQuestion("Where should the comma go? 'Although it was raining we went outside.'", ["After 'Although'", "After 'raining'", "After 'we'", "No comma needed"], ["After 'raining'"], "Use a comma after a fronted adverbial clause: 'Although it was raining, we went outside.'"),
        QuizQuestion("Which sentence uses a colon correctly?", ["I need: eggs, milk, and bread.", "I need the following items: eggs, milk, and bread.", "I need the following: items eggs milk and bread.", "I: need eggs milk and bread."], ["I need the following items: eggs, milk, and bread."], "A colon introduces a list after a complete clause."),

        // Grammar
        QuizQuestion("Which word is an adverb?", ["Quick", "Quickly", "Quicker", "Quickest"], ["Quickly"], "Adverbs often end in '-ly' and describe how something is done."),
        QuizQuestion("Which word is a conjunction?", ["Happy", "Because", "Quickly", "Beautiful"], ["Because"], "Conjunctions join clauses or sentences. 'Because' is a subordinating conjunction."),
        QuizQuestion("Identify the noun in this sentence: 'The cat sat on the mat.'", ["sat", "on", "cat", "the"], ["cat"], "A noun is a word that names a person, place, or thing. 'Cat' is the noun."),
        QuizQuestion("Which sentence is in the passive voice?", ["The dog chased the ball.", "The ball was chased by the dog.", "The dog is chasing the ball.", "The dog will chase the ball."], ["The ball was chased by the dog."], "In passive voice, the subject receives the action. 'The ball was chased' = passive."),
        QuizQuestion("What type of sentence is: 'Close the door!'", ["Question", "Statement", "Command", "Exclamation"], ["Command"], "A command (imperative sentence) tells someone to do something. It often starts with a verb."),

        // Vocabulary
        QuizQuestion("What is a synonym for 'happy'?", ["Sad", "Joyful", "Angry", "Tired"], ["Joyful"], "A synonym is a word with the same or similar meaning. 'Joyful' means very happy."),
        QuizQuestion("What is an antonym for 'brave'?", ["Courageous", "Bold", "Cowardly", "Daring"], ["Cowardly"], "An antonym is a word with the opposite meaning. 'Cowardly' is the opposite of 'brave'."),
        QuizQuestion("Choose the correct homophone: 'I can ___ the birds.'", ["here", "hear", "heer", "hare"], ["hear"], "'Hear' means to listen. 'Here' means in this place."),
        QuizQuestion("What does the prefix 'un-' mean?", ["Again", "Before", "Not", "After"], ["Not"], "The prefix 'un-' means 'not'. For example, 'unhappy' means 'not happy'."),
        QuizQuestion("Which word means 'very large'?", ["Tiny", "Enormous", "Average", "Miniature"], ["Enormous"], "'Enormous' means extremely large in size or quantity."),
    ]

    // MARK: - Question Generation Methods
    func generateSpellingQuestion(difficulty: QuestionDifficulty) -> QuizQuestion {
        let spellingQuestions = Self.fallbackBank.prefix(5)
        return spellingQuestions.randomElement()!
    }

    func generateGrammarQuestion(difficulty: QuestionDifficulty) -> QuizQuestion {
        let grammarQuestions = Self.fallbackBank.dropFirst(10).prefix(5)
        return grammarQuestions.randomElement()!
    }

    func generateVocabularyQuestion(difficulty: QuestionDifficulty) -> QuizQuestion {
        let vocabQuestions = Self.fallbackBank.dropFirst(15).prefix(5)
        return vocabQuestions.randomElement()!
    }

    /// Returns `count` shuffled fallback questions covering multiple SPAG areas.
    func generateQuestionsForTopic(_ topic: String, count: Int = 10) -> [QuizQuestion] {
        return Array(Self.fallbackBank.shuffled().prefix(count))
    }
}

// MARK: - Supporting Enums
enum QuestionDifficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var pointValue: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
}
