import Foundation
import SwiftUI
import UIKit

struct FeedbackPanel: View {
    var question: Question
    var result: MarkResult
    var rule: String?

    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme

    private static let praise = ["Brilliant!", "Well done!", "Super work!", "Fantastic!", "You got it!", "Spot on!"]
    private static let encouragement = ["Nearly!", "Good try!", "Not quite, but keep going!", "So close!"]

    private var headline: String {
        let options = result.correct ? Self.praise : Self.encouragement
        return options[abs(question.id.hashValue) % options.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                BuddyView(mood: result.correct ? .cheering : .encouraging, size: 56)
                Text(headline).pupilText(.title2, weight: .heavy)
                    .foregroundStyle(result.correct ? theme.correct : theme.tryAgain)
                Spacer()
                Button {
                    app.speech.speak(spokenFeedback)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Read this to me")
            }

            if !result.correct {
                VStack(alignment: .leading, spacing: 4) {
                    Text("The answer is:").pupilText(.subheadline, weight: .semibold).foregroundStyle(theme.secondaryText)
                    Text(CorrectAnswerText.for(question)).pupilText(.title3, weight: .bold)
                }
            }

            Text(question.explanation).pupilText(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((result.correct ? theme.correct : theme.tryAgain).opacity(0.12), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
        .onAppear {
            UIAccessibility.post(notification: .announcement, argument: spokenFeedback)
        }
    }

    private var spokenFeedback: String {
        result.correct
            ? "\(headline) \(question.explanation)"
            : "\(headline) The answer is \(CorrectAnswerText.for(question)). \(question.explanation)"
    }
}

enum CorrectAnswerText {
    static func `for`(_ question: Question) -> String {
        switch question.type {
        case .tapGap:
            AnswerMarker.render(tokens: question.tokens, mark: question.mark ?? "", gaps: question.gapAnswers)
        case .multiSelect:
            question.answers.joined(separator: " and ")
        case .multipleChoice, .spelling, .rewrite:
            question.answers.first ?? ""
        }
    }
}
