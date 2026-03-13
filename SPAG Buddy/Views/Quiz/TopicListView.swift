//
//  TopicListView.swift
//  SPAG Buddy
//
//  Displays topics within a category with progress indicators
//

import SwiftUI

struct TopicListView: View {
    let category: SPAGCategory
    @ObservedObject var studentData: StudentData
    @ObservedObject var achievementManager: AchievementManager
    @State private var searchText = ""
    @State private var selectedTopic: SPAGTopic?

    var filteredTopics: [SPAGTopic] {
        if searchText.isEmpty {
            return category.topics
        }
        return category.topics.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Dimensions.sectionSpacing) {
                    // Category header
                    categoryHeader

                    // Progress overview
                    categoryProgressCard

                    // Topic list
                    topicListSection

                    // Suggestion box
                    suggestionBox
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search topics")
        .navigationDestination(item: $selectedTopic) { topic in
            QuizView(
                topic: topic,
                category: category,
                studentData: studentData,
                achievementManager: achievementManager
            )
        }
    }

    // MARK: - Category Header
    private var categoryHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: category.icon)
                    .font(.system(size: 28))
                    .foregroundColor(category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(category.description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Category Progress Card
    private var categoryProgressCard: some View {
        let progress = getCategoryProgress()
        let topicsMastered = getMasteredCount()

        return HStack(spacing: 16) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(category.color.opacity(0.15), lineWidth: 6)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: progress / 100)
                    .stroke(category.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(progress))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(category.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Overall Progress")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("\(topicsMastered) of \(category.topics.count) topics explored")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                // Mini progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(category.color.opacity(0.15))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(category.color)
                            .frame(width: geometry.size.width * (progress / 100), height: 6)
                    }
                }
                .frame(height: 6)
            }

            Spacer()
        }
        .cardStyle()
    }

    // MARK: - Topic List Section
    private var topicListSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.itemSpacing) {
            HStack {
                Text("Topics")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Text("\(filteredTopics.count) topics")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            ForEach(filteredTopics) { topic in
                TopicRow(
                    topic: topic,
                    category: category,
                    progress: getTopicProgress(topic.name),
                    attempts: getTopicAttempts(topic.name)
                )
                .onTapGesture {
                    selectedTopic = topic
                }
            }
        }
    }

    // MARK: - Suggestion Box
    private var suggestionBox: some View {
        VStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundColor(AppTheme.Colors.xp)

            Text("Study Tip")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text(studyTip)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Dimensions.cornerRadiusLarge)
                .fill(AppTheme.Colors.xp.opacity(0.08))
        )
    }

    // MARK: - Helpers
    private var studyTip: String {
        switch category {
        case .spelling:
            return "Try to learn spelling rules rather than memorising individual words. Patterns like 'i before e except after c' can help you spell many words correctly!"
        case .punctuation:
            return "Read your sentences aloud. Where you naturally pause is often where punctuation belongs. Short pause? Try a comma. Full stop? That's a full stop!"
        case .grammar:
            return "Understanding word classes (nouns, verbs, adjectives) is the foundation of grammar. Once you know these, everything else clicks into place!"
        case .vocabulary:
            return "When you learn a new word, try to use it in a sentence three times during the day. This helps move it from your short-term to long-term memory!"
        }
    }

    private func getCategoryProgress() -> Double {
        let categoryTopics = studentData.performanceHistory.filter { key, _ in
            category.topics.contains(where: { key.contains($0.name) })
        }
        guard !categoryTopics.isEmpty else { return 0 }
        let totalScore = categoryTopics.values.reduce(0.0) { $0 + $1.averageScore }
        return totalScore / Double(categoryTopics.count)
    }

    private func getMasteredCount() -> Int {
        return studentData.performanceHistory.filter { key, value in
            category.topics.contains(where: { key.contains($0.name) }) && value.averageScore >= 70
        }.count
    }

    private func getTopicProgress(_ topicName: String) -> Double {
        return studentData.performanceHistory[topicName]?.averageScore ?? 0
    }

    private func getTopicAttempts(_ topicName: String) -> Int {
        return studentData.performanceHistory[topicName]?.attempts.count ?? 0
    }
}

// MARK: - Topic Row
struct TopicRow: View {
    let topic: SPAGTopic
    let category: SPAGCategory
    let progress: Double
    let attempts: Int

    var body: some View {
        HStack(spacing: 14) {
            // Progress indicator
            ZStack {
                Circle()
                    .stroke(category.color.opacity(0.15), lineWidth: 3)
                    .frame(width: 40, height: 40)

                if progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress / 100)
                        .stroke(category.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                }

                if progress >= 80 {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(category.color)
                } else {
                    Text("\(Int(progress))%")
                        .font(.system(size: 10))
                        .fontWeight(.medium)
                        .foregroundColor(progress > 0 ? category.color : AppTheme.Colors.textTertiary)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(topic.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                HStack(spacing: 8) {
                    Text("\(topic.questionCount) questions")
                        .font(.caption2)
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    if attempts > 0 {
                        Text("\(attempts) attempt\(attempts == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }

            Spacer()

            // Status icon
            Image(systemName: progress >= 80 ? "star.fill" : "chevron.right")
                .font(.caption)
                .foregroundColor(progress >= 80 ? AppTheme.Colors.xp : AppTheme.Colors.textTertiary)
        }
        .padding(AppTheme.Dimensions.cardPadding)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

// MARK: - SPAGTopic Hashable Conformance
extension SPAGTopic: Hashable {
    static func == (lhs: SPAGTopic, rhs: SPAGTopic) -> Bool {
        lhs.name == rhs.name && lhs.filename == rhs.filename
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(filename)
    }
}

// MARK: - SPAGCategory Hashable Conformance
extension SPAGCategory: Hashable {}

#Preview {
    NavigationStack {
        TopicListView(
            category: .spelling,
            studentData: StudentData(),
            achievementManager: AchievementManager()
        )
    }
}
