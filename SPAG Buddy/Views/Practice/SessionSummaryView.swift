import Foundation
import SwiftUI

struct SessionSummaryView: View {
    var session: PracticeSession
    var pupil: PupilProfile
    var onDone: () -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if session.questions.isEmpty {
                    BuddySays(text: "There are no questions here yet. Try another topic!", mood: .thinking)
                } else if let outcome = session.outcome {
                    BuddyView(mood: .cheering, size: 120)
                    Text(title(for: outcome))
                        .pupilText(.largeTitle, weight: .heavy)
                        .multilineTextAlignment(.center)
                    Text("You got \(outcome.correct) out of \(outcome.total) right.")
                        .pupilText(.title2, weight: .semibold)

                    HStack(spacing: 12) {
                        StatPill(systemImage: "star.fill", value: "+\(outcome.starsEarned)", label: "stars", color: theme.star)
                        StatPill(systemImage: "flame.fill", value: "\(pupil.currentStreak)", label: "day streak", color: theme.tryAgain)
                    }

                    if !outcome.newBadges.isEmpty {
                        VStack(spacing: 12) {
                            Text("New sticker!").pupilText(.title2, weight: .heavy)
                            ForEach(outcome.newBadges) { badge in
                                HStack(spacing: 14) {
                                    Text(badge.emoji).font(.system(size: 44))
                                    VStack(alignment: .leading) {
                                        Text(badge.title).pupilText(.headline, weight: .bold)
                                        Text(badge.detail).pupilText(.subheadline).foregroundStyle(theme.secondaryText)
                                    }
                                    Spacer()
                                }
                                .card(padding: 14)
                            }
                        }
                    }

                    if !session.mode.givesInstantFeedback {
                        review
                    }
                }

                Button("Finish", action: onDone)
                    .buttonStyle(.big)
            }
            .padding(24)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
    }

    private func title(for outcome: SessionOutcome) -> String {
        let ratio = outcome.total == 0 ? 0 : Double(outcome.correct) / Double(outcome.total)
        switch ratio {
        case 0.9...: return "Amazing!"
        case 0.6..<0.9: return "Great work!"
        default: return "Well done for trying!"
        }
    }

    /// SATs practice holds back answers until the end, so show them all here.
    private var review: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Check your answers").pupilText(.title2, weight: .heavy)
            ForEach(Array(session.results.enumerated()), id: \.element.id) { index, item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: item.result.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(item.result.correct ? theme.correct : theme.tryAgain)
                        Text("\(index + 1). \(item.question.prompt)").pupilText(.headline, weight: .semibold)
                    }
                    if !item.result.correct {
                        Text("You said: \(item.result.answerGiven)").pupilText(.subheadline).foregroundStyle(theme.secondaryText)
                        Text("Answer: \(CorrectAnswerText.for(item.question))").pupilText(.subheadline, weight: .bold)
                    }
                    Text(item.question.explanation).pupilText(.footnote).foregroundStyle(theme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card(padding: 14)
            }
        }
    }
}
