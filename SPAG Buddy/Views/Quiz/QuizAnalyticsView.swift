//
//  QuizAnalyticsView.swift
//  SPAG Buddy
//
//  Displays quiz analytics with average scores and recent attempts
//

import SwiftUI

struct QuizAnalyticsView: View {
    @ObservedObject var quizData: QuizData

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Dimensions.sectionSpacing) {
                        averageScoreCard
                        recentAttemptsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Quiz Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Average Score Card
    private var averageScoreCard: some View {
        VStack(spacing: 16) {
            Text("Average Score")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)

            let average = quizData.getAverageScore()
            let color = scoreColor(for: average)

            ZStack {
                Circle()
                    .stroke(color.opacity(0.12), lineWidth: 12)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: average / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(average))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            Text(averageMessage(for: average))
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .cardStyle()
    }

    // MARK: - Recent Attempts
    private var recentAttemptsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.itemSpacing) {
            Text("Recent Attempts")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)

            if quizData.attempts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    Text("No attempts yet")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Text("Complete a quiz to see your results here")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(quizData.attempts.suffix(10).reversed()) { attempt in
                    AttemptRow(attempt: attempt)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Helpers
    private func scoreColor(for score: Double) -> Color {
        switch score {
        case 80...100: return AppTheme.Colors.correct
        case 60..<80: return AppTheme.Colors.vocabulary
        default: return AppTheme.Colors.incorrect
        }
    }

    private func averageMessage(for score: Double) -> String {
        switch score {
        case 80...100: return "Excellent work! Keep it up!"
        case 60..<80: return "Good progress! Keep practising!"
        case 1..<60: return "Keep going! Practice makes perfect!"
        default: return "Start a quiz to track your progress!"
        }
    }
}

// MARK: - Attempt Row
struct AttemptRow: View {
    let attempt: QuizAttemptRecord

    private var percentage: Double {
        guard attempt.totalQuestions > 0 else { return 0 }
        return Double(attempt.score) / Double(attempt.totalQuestions) * 100
    }

    private var color: Color {
        switch percentage {
        case 80...100: return AppTheme.Colors.correct
        case 60..<80: return AppTheme.Colors.vocabulary
        default: return AppTheme.Colors.incorrect
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Score indicator
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Text("\(Int(percentage))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(attempt.topic)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("\(attempt.score)/\(attempt.totalQuestions) correct")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            Text(attempt.date, style: .relative)
                .font(.caption2)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    QuizAnalyticsView(quizData: QuizData())
}
