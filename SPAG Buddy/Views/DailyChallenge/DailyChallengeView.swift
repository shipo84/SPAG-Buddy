//
//  DailyChallengeView.swift
//  SPAG Buddy
//
//  Daily challenge quiz feature with themed styling
//

import SwiftUI

struct DailyChallengeView: View {
    @ObservedObject var challengeManager: DailyChallengeManager
    @ObservedObject var studentData: StudentData
    @ObservedObject var achievementManager: AchievementManager
    @Environment(\.dismiss) var dismiss

    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: String? = nil
    @State private var hasChecked = false
    @State private var showingResults = false
    @State private var score = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppTheme.Colors.background,
                        (challengeManager.todaysChallenge?.color ?? AppTheme.Colors.accent).opacity(0.08)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if let challenge = challengeManager.todaysChallenge {
                    if challengeManager.isChallengeCompleted && !showingResults {
                        completedView(challenge: challenge)
                    } else if showingResults {
                        resultsView(challenge: challenge)
                    } else {
                        challengeContent(challenge: challenge)
                    }
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading challenge...")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .navigationTitle("Daily Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                }
            }
        }
    }

    // MARK: - Challenge Content
    private func challengeContent(challenge: DailyChallenge) -> some View {
        VStack(spacing: 20) {
            // Challenge header
            VStack(spacing: 12) {
                Image(systemName: challenge.icon)
                    .font(.system(size: 44))
                    .foregroundColor(challenge.color)

                Text(challenge.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(challenge.description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<challenge.questions.count, id: \.self) { index in
                        Circle()
                            .fill(index < currentQuestionIndex ? AppTheme.Colors.correct :
                                  index == currentQuestionIndex ? challenge.color :
                                  AppTheme.Colors.textTertiary.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.top, 20)

            Spacer()

            // Question
            if currentQuestionIndex < challenge.questions.count {
                let question = challenge.questions[currentQuestionIndex]

                VStack(spacing: 20) {
                    Text(question.text)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .padding(.horizontal)

                    // Answer options
                    VStack(spacing: 10) {
                        ForEach(question.options, id: \.self) { option in
                            Button(action: {
                                if !hasChecked {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedAnswer = option
                                    }
                                }
                            }) {
                                HStack {
                                    Text(option)
                                        .font(.body)
                                        .fontWeight(selectedAnswer == option ? .medium : .regular)
                                        .multilineTextAlignment(.leading)

                                    Spacer()

                                    if hasChecked && selectedAnswer == option {
                                        Image(systemName: option == question.correctAnswer ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(option == question.correctAnswer ? AppTheme.Colors.correct : AppTheme.Colors.incorrect)
                                    } else if hasChecked && option == question.correctAnswer {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(AppTheme.Colors.correct.opacity(0.6))
                                    } else if selectedAnswer == option {
                                        Image(systemName: "circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(AppTheme.Colors.accent)
                                    } else {
                                        Image(systemName: "circle")
                                            .font(.caption2)
                                            .foregroundColor(AppTheme.Colors.textTertiary)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Dimensions.cornerRadiusMedium)
                                        .fill(optionBackgroundColor(for: option, correctAnswer: question.correctAnswer))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Dimensions.cornerRadiusMedium)
                                        .stroke(optionBorderColor(for: option, correctAnswer: question.correctAnswer), lineWidth: selectedAnswer == option || (hasChecked && option == question.correctAnswer) ? 2 : 0.5)
                                )
                                .foregroundColor(optionForegroundColor(for: option, correctAnswer: question.correctAnswer))
                            }
                            .disabled(hasChecked)
                        }
                    }
                    .padding(.horizontal)

                    // Check/Next button
                    if !hasChecked {
                        Button("Check Answer") {
                            checkAnswer(correctAnswer: question.correctAnswer)
                        }
                        .buttonStyle(PrimaryButtonStyle(color: challenge.color))
                        .disabled(selectedAnswer == nil)
                        .opacity(selectedAnswer == nil ? 0.5 : 1.0)
                        .padding(.horizontal)
                    } else {
                        Button(currentQuestionIndex < challenge.questions.count - 1 ? "Next Question" : "See Results") {
                            nextQuestion(challenge: challenge)
                        }
                        .buttonStyle(PrimaryButtonStyle(color: challenge.color))
                        .padding(.horizontal)
                    }
                }
            }

            Spacer()

            // Bonus XP indicator
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(AppTheme.Colors.xp)
                Text("Bonus: +\(challenge.bonusXP) XP")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.Colors.cardBackground.opacity(0.9))
            .cornerRadius(20)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Results View
    private func resultsView(challenge: DailyChallenge) -> some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: score >= 3 ? "star.fill" : "star.leadinghalf.filled")
                    .font(.system(size: 70))
                    .foregroundColor(AppTheme.Colors.xp)

                Text("Challenge Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("\(score) out of \(challenge.questions.count) correct")
                    .font(.title3)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                let percentScore = Double(score) / Double(challenge.questions.count)
                let xpEarned = Int(Double(challenge.bonusXP) * percentScore)

                VStack(spacing: 8) {
                    Text("You earned:")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    HStack(spacing: 16) {
                        Label("\(xpEarned) XP", systemImage: "star.fill")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.Colors.xp)

                        if challengeManager.dailyChallengeStreak > 1 {
                            Label("\(challengeManager.dailyChallengeStreak) day streak!", systemImage: "flame.fill")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.Colors.streak)
                        }
                    }
                }
                .padding(.top)
            }

            Spacer()

            Button("Continue") {
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle(color: challenge.color))
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .onAppear {
            let percentScore = Double(score) / Double(challenge.questions.count)
            let xpEarned = Int(Double(challenge.bonusXP) * percentScore)
            studentData.studentProfile.experiencePoints += xpEarned

            achievementManager.checkAndUnlockAchievements(
                studentData: studentData,
                currentStreak: challengeManager.dailyChallengeStreak
            )
        }
    }

    // MARK: - Completed View
    private func completedView(challenge: DailyChallenge) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 70))
                .foregroundColor(AppTheme.Colors.correct)

            Text("Already Completed!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text("You've completed today's challenge.\nCome back tomorrow for a new one!")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal)

            if challengeManager.dailyChallengeStreak > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppTheme.Colors.streak)
                    Text("\(challengeManager.dailyChallengeStreak) day streak")
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                .font(.title3)
                .padding(.top)
            }

            Spacer()

            Button("OK") {
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle(color: AppTheme.Colors.textTertiary))
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Helper Methods
    private func checkAnswer(correctAnswer: String) {
        guard let selected = selectedAnswer else { return }
        hasChecked = true
        if selected == correctAnswer {
            score += 1
        }
    }

    private func nextQuestion(challenge: DailyChallenge) {
        if currentQuestionIndex < challenge.questions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
                selectedAnswer = nil
                hasChecked = false
            }
        } else {
            challengeManager.completeChallenge(
                score: score,
                totalQuestions: challenge.questions.count
            )
            withAnimation {
                showingResults = true
            }
        }
    }

    private func optionBackgroundColor(for option: String, correctAnswer: String) -> Color {
        if hasChecked {
            if selectedAnswer == option {
                return option == correctAnswer ? AppTheme.Colors.correct.opacity(0.12) : AppTheme.Colors.incorrect.opacity(0.12)
            }
            if option == correctAnswer {
                return AppTheme.Colors.correct.opacity(0.08)
            }
            return AppTheme.Colors.cardBackground
        }
        return selectedAnswer == option ? AppTheme.Colors.accent.opacity(0.08) : AppTheme.Colors.cardBackground
    }

    private func optionBorderColor(for option: String, correctAnswer: String) -> Color {
        if hasChecked {
            if selectedAnswer == option {
                return option == correctAnswer ? AppTheme.Colors.correct : AppTheme.Colors.incorrect
            }
            if option == correctAnswer {
                return AppTheme.Colors.correct.opacity(0.5)
            }
            return Color.clear
        }
        return selectedAnswer == option ? AppTheme.Colors.accent : Color.clear
    }

    private func optionForegroundColor(for option: String, correctAnswer: String) -> Color {
        if hasChecked && selectedAnswer == option {
            return option == correctAnswer ? AppTheme.Colors.correct : AppTheme.Colors.incorrect
        }
        return selectedAnswer == option ? AppTheme.Colors.accent : AppTheme.Colors.textPrimary
    }
}

#Preview {
    DailyChallengeView(
        challengeManager: DailyChallengeManager(),
        studentData: StudentData(),
        achievementManager: AchievementManager()
    )
}
