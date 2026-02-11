//
//  QuizView.swift
//  SPAG Buddy
//
//  Interactive quiz view with questions, feedback, and scoring
//

import SwiftUI

struct QuizView: View {
    let topic: SPAGTopic
    let category: SPAGCategory
    @ObservedObject var studentData: StudentData
    @ObservedObject var achievementManager: AchievementManager
    @Environment(\.dismiss) var dismiss

    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var hasChecked = false
    @State private var score = 0
    @State private var showingResults = false
    @State private var isLoading = true
    @State private var showExplanation = false

    private var currentQuestion: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    private var isCorrect: Bool {
        guard let selected = selectedAnswer, let question = currentQuestion else { return false }
        return question.correctAnswers.contains(selected)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            if isLoading {
                loadingView
            } else if showingResults {
                resultsView
            } else if let question = currentQuestion {
                questionView(question)
            } else {
                emptyView
            }
        }
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !showingResults && !isLoading {
                    Text("\(currentIndex + 1)/\(questions.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.Colors.cardBackground)
                        .cornerRadius(12)
                }
            }
        }
        .onAppear {
            loadQuestions()
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading questions...")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.folder.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textTertiary)

            Text("No questions available")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textSecondary)

            Text("Questions for this topic are coming soon!")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textTertiary)

            Button("Go Back") {
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle(color: category.color))
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Question View
    private func questionView(_ question: QuizQuestion) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Progress bar
                progressBar

                VStack(spacing: AppTheme.Dimensions.sectionSpacing) {
                    // Topic context
                    topicContextBanner

                    // Question text
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Question \(currentIndex + 1)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(category.color)

                        Text(question.question)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Answer options
                    VStack(spacing: 10) {
                        ForEach(question.options, id: \.self) { option in
                            AnswerOptionButton(
                                text: option,
                                isSelected: selectedAnswer == option,
                                isCorrect: hasChecked ? question.correctAnswers.contains(option) : nil,
                                wasSelected: hasChecked && selectedAnswer == option,
                                isDisabled: hasChecked
                            ) {
                                if !hasChecked {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedAnswer = option
                                    }
                                }
                            }
                        }
                    }

                    // Explanation (shown after checking)
                    if hasChecked {
                        explanationCard(question)
                    }

                    Spacer(minLength: 20)

                    // Action button
                    actionButton
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(category.color.opacity(0.1))
                    .frame(height: 4)

                Rectangle()
                    .fill(category.color)
                    .frame(width: geometry.size.width * (Double(currentIndex) / Double(max(questions.count, 1))), height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Topic Context Banner
    private var topicContextBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: category.icon)
                .font(.subheadline)
                .foregroundColor(category.color)

            Text(category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(category.color)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(AppTheme.Colors.textTertiary)

            Text(topic.name)
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(category.color.opacity(0.06))
        .cornerRadius(AppTheme.Dimensions.cornerRadiusSmall)
    }

    // MARK: - Explanation Card
    private func explanationCard(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? AppTheme.Colors.correct : AppTheme.Colors.incorrect)
                Text(isCorrect ? "Correct!" : "Not quite right")
                    .font(.headline)
                    .foregroundColor(isCorrect ? AppTheme.Colors.correct : AppTheme.Colors.incorrect)
            }

            Divider()

            Text(question.explanation)
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !isCorrect {
                HStack(spacing: 4) {
                    Text("Correct answer:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Text(question.correctAnswers.joined(separator: ", "))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.correct)
                }
            }
        }
        .padding(AppTheme.Dimensions.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Dimensions.cornerRadiusMedium)
                .fill(isCorrect ? AppTheme.Colors.correct.opacity(0.08) : AppTheme.Colors.incorrect.opacity(0.08))
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Action Button
    private var actionButton: some View {
        Group {
            if !hasChecked {
                Button("Check Answer") {
                    checkAnswer()
                }
                .buttonStyle(PrimaryButtonStyle(color: category.color))
                .disabled(selectedAnswer == nil)
                .opacity(selectedAnswer == nil ? 0.5 : 1.0)
            } else {
                Button(currentIndex < questions.count - 1 ? "Next Question" : "See Results") {
                    nextQuestion()
                }
                .buttonStyle(PrimaryButtonStyle(color: category.color))
            }
        }
    }

    // MARK: - Results View
    private var resultsView: some View {
        QuizScoreView(
            score: score,
            totalQuestions: questions.count,
            onDismiss: {
                dismiss()
            }
        )
    }

    // MARK: - Actions
    private func loadQuestions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let loaded = QuestionLoaderService.loadQuestions(from: topic.filename)
            if loaded.isEmpty {
                // Generate sample questions as fallback
                questions = QuestionGenerator().generateQuestionsForTopic(topic.name, count: 10)
            } else {
                questions = Array(loaded.shuffled().prefix(10))
            }
            isLoading = false
        }
    }

    private func checkAnswer() {
        guard selectedAnswer != nil else { return }
        hasChecked = true

        if isCorrect {
            score += 1
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            showExplanation = true
        }
    }

    private func nextQuestion() {
        if currentIndex < questions.count - 1 {
            withAnimation {
                currentIndex += 1
                selectedAnswer = nil
                hasChecked = false
                showExplanation = false
            }
        } else {
            // Record attempt and show results
            studentData.recordAttempt(
                topic: topic.name,
                score: score,
                total: questions.count
            )

            achievementManager.checkAndUnlockAchievements(
                studentData: studentData,
                currentStreak: 0
            )

            withAnimation {
                showingResults = true
            }
        }
    }
}

// MARK: - Answer Option Button
struct AnswerOptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool?
    let wasSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    private var backgroundColor: Color {
        if let correct = isCorrect {
            if wasSelected {
                return correct ? AppTheme.Colors.correct.opacity(0.12) : AppTheme.Colors.incorrect.opacity(0.12)
            }
            if correct {
                return AppTheme.Colors.correct.opacity(0.08)
            }
            return AppTheme.Colors.cardBackground
        }
        return isSelected ? AppTheme.Colors.accent.opacity(0.08) : AppTheme.Colors.cardBackground
    }

    private var borderColor: Color {
        if let correct = isCorrect {
            if wasSelected {
                return correct ? AppTheme.Colors.correct : AppTheme.Colors.incorrect
            }
            if correct {
                return AppTheme.Colors.correct.opacity(0.5)
            }
            return Color.clear
        }
        return isSelected ? AppTheme.Colors.accent : Color.clear
    }

    private var textColor: Color {
        if let correct = isCorrect, wasSelected {
            return correct ? AppTheme.Colors.correct : AppTheme.Colors.incorrect
        }
        return isSelected ? AppTheme.Colors.accent : AppTheme.Colors.textPrimary
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)

                Spacer()

                if let correct = isCorrect {
                    if wasSelected {
                        Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(correct ? AppTheme.Colors.correct : AppTheme.Colors.incorrect)
                    } else if correct {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(AppTheme.Colors.correct.opacity(0.6))
                    }
                } else if isSelected {
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
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.cornerRadiusMedium)
                    .stroke(borderColor, lineWidth: isSelected || (isCorrect != nil) ? 2 : 0.5)
            )
        }
        .disabled(isDisabled)
    }
}

#Preview {
    NavigationStack {
        QuizView(
            topic: SPAGTopic(name: "Homophones", filename: "Homophones_Enhanced", questionCount: 30),
            category: .spelling,
            studentData: StudentData(),
            achievementManager: AchievementManager()
        )
    }
}
