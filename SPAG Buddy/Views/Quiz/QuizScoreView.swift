//
//  QuizScoreView.swift
//  SPAG Buddy
//
//  Displays quiz results and performance feedback
//

import SwiftUI

// MARK: - Quiz Results View
struct QuizScoreView: View {
    let score: Int
    let totalQuestions: Int
    let onDismiss: () -> Void

    @State private var animateCircle = false

    private var percentage: Double {
        return Double(score) / Double(totalQuestions) * 100
    }

    private var performanceMessage: String {
        switch percentage {
        case 90...100:
            return "Outstanding! You're a SPAG superstar!"
        case 80..<90:
            return "Great job! You're doing really well!"
        case 70..<80:
            return "Good work! Keep practising!"
        case 60..<70:
            return "Nice try! A bit more practice will help!"
        default:
            return "Keep learning! Every try makes you better!"
        }
    }

    private var performanceIcon: String {
        switch percentage {
        case 90...100: return "star.fill"
        case 80..<90: return "hand.thumbsup.fill"
        case 70..<80: return "face.smiling.fill"
        case 60..<70: return "book.fill"
        default: return "lightbulb.fill"
        }
    }

    private var performanceColor: Color {
        switch percentage {
        case 90...100: return AppTheme.Colors.correct
        case 80..<90: return AppTheme.Colors.accent
        case 70..<80: return AppTheme.Colors.vocabulary
        default: return AppTheme.Colors.incorrect
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Score circle
            ZStack {
                Circle()
                    .stroke(performanceColor.opacity(0.12), lineWidth: 20)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: animateCircle ? CGFloat(percentage / 100) : 0)
                    .stroke(performanceColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(Int(percentage))%")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(performanceColor)

                    Text("\(score)/\(totalQuestions)")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }

            // Performance message
            VStack(spacing: 12) {
                Image(systemName: performanceIcon)
                    .font(.system(size: 32))
                    .foregroundColor(performanceColor)

                Text("Quiz Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(performanceMessage)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(performanceColor)
            }

            // Performance breakdown
            VStack(spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppTheme.Colors.correct)
                            .frame(width: 8, height: 8)
                        Text("Correct")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Text("\(score)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.correct)
                }

                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppTheme.Colors.incorrect)
                            .frame(width: 8, height: 8)
                        Text("Incorrect")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Text("\(totalQuestions - score)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.incorrect)
                }

                Divider()

                HStack {
                    Text("Final Score")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                    Text("\(Int(percentage))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(performanceColor)
                }
            }
            .padding(AppTheme.Dimensions.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.cornerRadiusMedium)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button("Continue Learning") {
                    onDismiss()
                }
                .buttonStyle(PrimaryButtonStyle(color: performanceColor))

                if percentage < 80 {
                    Button("Try Again") {
                        onDismiss()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Dimensions.cornerRadiusMedium)
                            .stroke(AppTheme.Colors.accent, lineWidth: 1.5)
                    )
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.background)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                animateCircle = true
            }
        }
    }
}

#Preview {
    QuizScoreView(
        score: 7,
        totalQuestions: 10,
        onDismiss: {}
    )
}
