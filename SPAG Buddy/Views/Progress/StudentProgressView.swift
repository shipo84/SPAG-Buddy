//
//  StudentProgressView.swift
//  SPAG Buddy
//
//  Student progress tracking with achievements and performance overview
//

import SwiftUI
import Charts

struct StudentProgressView: View {
    @ObservedObject var studentData: StudentData
    @ObservedObject var achievementManager: AchievementManager
    @State private var selectedTimeRange = TimeRange.week
    @State private var showingAchievementDetail = false
    @State private var selectedAchievement: Achievement?
    @State private var showingAllAchievements = false

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Dimensions.sectionSpacing) {
                        profileCard
                        performanceOverview
                        progressChart
                        achievementsSection
                        recommendedTopics
                    }
                    .padding()
                }
            }
            .navigationTitle("My Progress")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showingAllAchievements) {
                AchievementsListView(achievementManager: achievementManager)
            }
        }
        .sheet(isPresented: $showingAchievementDetail) {
            if let achievement = selectedAchievement {
                AchievementDetailView(achievement: achievement, isUnlocked: achievementManager.unlockedAchievements.contains(achievement.id))
            }
        }
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Level \(studentData.studentProfile.level)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("\(studentData.studentProfile.experiencePoints) XP")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    // XP Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.Colors.accent.opacity(0.12))
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.Gradients.xpBar)
                                .frame(width: geometry.size.width * (Double(studentData.studentProfile.experiencePoints % 1000) / 1000), height: 12)
                        }
                    }
                    .frame(height: 12)
                }

                Spacer()

                // Owl avatar
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accent.opacity(0.12))
                        .frame(width: 80, height: 80)

                    VStack(spacing: 2) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(AppTheme.Colors.accent)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 5, height: 5)
                                        .offset(x: 1.5, y: -1.5)
                                )
                            Circle()
                                .fill(AppTheme.Colors.accent)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 5, height: 5)
                                        .offset(x: 1.5, y: -1.5)
                                )
                        }
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.orange)
                            .rotationEffect(.degrees(180))
                    }
                }
            }

            // Stats Row
            HStack(spacing: 20) {
                StatItem(title: "Topics Mastered", value: "\(studentData.performanceHistory.filter { $0.value.averageScore >= 80 }.count)")
                StatItem(title: "Total Attempts", value: "\(studentData.performanceHistory.values.reduce(0) { $0 + $1.attempts.count })")
                StatItem(title: "Achievements", value: "\(achievementManager.unlockedAchievements.count)")
            }
        }
        .cardStyle()
    }

    // MARK: - Performance Overview
    private var performanceOverview: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.itemSpacing) {
            Text("Performance Overview")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)

            VStack(spacing: 10) {
                PerformanceRow(subject: "Spelling", score: getAverageScore(for: "Spelling"), color: AppTheme.Colors.spelling)
                PerformanceRow(subject: "Punctuation", score: getAverageScore(for: "Punctuation"), color: AppTheme.Colors.punctuation)
                PerformanceRow(subject: "Grammar", score: getAverageScore(for: "Grammar"), color: AppTheme.Colors.grammar)
                PerformanceRow(subject: "Vocabulary", score: getAverageScore(for: "Vocabulary"), color: AppTheme.Colors.vocabulary)
            }
        }
        .cardStyle()
    }

    // MARK: - Progress Chart
    private var progressChart: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.itemSpacing) {
            HStack {
                Text("Progress Trend")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }

            RoundedRectangle(cornerRadius: AppTheme.Dimensions.cornerRadiusMedium)
                .fill(AppTheme.Colors.accent.opacity(0.06))
                .frame(height: 200)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.Colors.accent.opacity(0.4))
                        Text("Start practising to see your progress!")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                )
        }
        .cardStyle()
    }

    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.itemSpacing) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Button {
                    showingAllAchievements = true
                } label: {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.accent)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Achievement.allAchievements.prefix(5)) { achievement in
                        AchievementBadge(
                            achievement: achievement,
                            isUnlocked: achievementManager.unlockedAchievements.contains(achievement.id)
                        )
                        .onTapGesture {
                            selectedAchievement = achievement
                            showingAchievementDetail = true
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Recommended Topics
    private var recommendedTopics: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.itemSpacing) {
            Text("Recommended for You")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)

            if studentData.getRecommendedTopics().isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.Colors.xp)

                    Text("Complete some exercises to get personalised recommendations")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(studentData.getRecommendedTopics(), id: \.self) { topic in
                    RecommendedTopicRow(topic: topic)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Helper Methods
    private func getAverageScore(for category: String) -> Double {
        let categoryTopics = studentData.performanceHistory.filter { $0.key.contains(category) }
        guard !categoryTopics.isEmpty else { return 0 }

        let totalScore = categoryTopics.values.reduce(0.0) { $0 + $1.averageScore }
        return totalScore / Double(categoryTopics.count)
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.accent)

            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PerformanceRow: View {
    let subject: String
    let score: Double
    let color: Color

    var body: some View {
        HStack {
            Text(subject)
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer()

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.12))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * (score / 100), height: 8)
                }
            }
            .frame(width: 100, height: 8)

            Text("\(Int(score))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.color : AppTheme.Colors.textTertiary.opacity(0.3))
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? .white : AppTheme.Colors.textTertiary)
            }

            Text(achievement.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(isUnlocked ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                .frame(width: 80)
        }
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

struct RecommendedTopicRow: View {
    let topic: String

    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(AppTheme.Colors.xp)

            Text(topic)
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Achievement Detail Views

struct AchievementDetailView: View {
    let achievement: Achievement
    let isUnlocked: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(isUnlocked ? achievement.color : AppTheme.Colors.textTertiary.opacity(0.3))
                        .frame(width: 120, height: 120)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 60))
                        .foregroundColor(isUnlocked ? .white : AppTheme.Colors.textTertiary)
                }

                Text(achievement.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(achievement.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.horizontal)

                if isUnlocked {
                    Label("\(achievement.points) Points", systemImage: "star.fill")
                        .foregroundColor(AppTheme.Colors.xp)
                } else {
                    Text("Locked")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct AchievementsListView: View {
    @ObservedObject var achievementManager: AchievementManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    var columns: [GridItem] {
        if isIPad {
            return [GridItem(.flexible()), GridItem(.flexible())]
        } else {
            return [GridItem(.flexible())]
        }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if Achievement.allAchievements.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.Colors.warning)
                    Text("No achievements loaded")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("Please check the achievement configuration")
                        .font(.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Achievement.allAchievements) { achievement in
                            AchievementListRow(
                                achievement: achievement,
                                isUnlocked: achievementManager.unlockedAchievements.contains(achievement.id)
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("All Achievements")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct AchievementListRow: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.color : AppTheme.Colors.textTertiary.opacity(0.3))
                    .frame(width: 50, height: 50)

                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(isUnlocked ? .white : AppTheme.Colors.textTertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            if isUnlocked {
                Text("\(achievement.points)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(achievement.color)
            }
        }
        .padding(AppTheme.Dimensions.cardPadding)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.Dimensions.cornerRadiusMedium)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    StudentProgressView(studentData: StudentData(), achievementManager: AchievementManager())
}
