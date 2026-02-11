//
//  ContentView.swift
//  SPAG Buddy
//
//  Main navigation view for the SPAG Buddy app
//  Evolved UI with owl mascot and modern card-based design
//

import SwiftUI

struct ContentView: View {
    @StateObject private var studentData = StudentData()
    @StateObject private var achievementManager = AchievementManager()
    @StateObject private var challengeManager = DailyChallengeManager()
    @StateObject private var quizData = QuizData()
    @State private var showingDailyChallenge = false
    @State private var selectedCategory: SPAGCategory?

    var body: some View {
        TabView {
            // MARK: - Home Tab
            NavigationStack {
                ZStack {
                    AppTheme.Colors.background.ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Dimensions.sectionSpacing) {
                            // Owl mascot and greeting
                            owlHeader

                            // SPAG Test of the Day
                            testOfTheDayCard

                            // Daily Challenge card
                            dailyChallengeCard

                            // Categories section
                            categoriesSection

                            // Quick progress summary
                            quickProgressCard

                            // Word of the day
                            wordOfTheDayCard
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
                .navigationTitle("SPAG Buddy")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(item: $selectedCategory) { category in
                    TopicListView(
                        category: category,
                        studentData: studentData,
                        achievementManager: achievementManager
                    )
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            // MARK: - Progress Tab
            StudentProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }

            // MARK: - Settings Tab
            NavigationStack {
                ZStack {
                    AppTheme.Colors.background.ignoresSafeArea()

                    settingsContent
                }
                .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(AppTheme.Colors.accent)
        .sheet(isPresented: $showingDailyChallenge) {
            DailyChallengeView(
                challengeManager: challengeManager,
                studentData: studentData,
                achievementManager: achievementManager
            )
        }
    }

    // MARK: - Owl Header
    private var owlHeader: some View {
        HStack(spacing: 16) {
            // Owl mascot
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppTheme.Colors.accent.opacity(0.15),
                                AppTheme.Colors.grammar.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                // Owl face using SF Symbols
                VStack(spacing: 2) {
                    // Eyes
                    HStack(spacing: 12) {
                        Circle()
                            .fill(AppTheme.Colors.accent)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 2, y: -2)
                            )
                        Circle()
                            .fill(AppTheme.Colors.accent)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 2, y: -2)
                            )
                    }
                    // Beak
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                        .rotationEffect(.degrees(180))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Ready to practise your SPAG skills?")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                // Level badge
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.xp)
                    Text("Level \(studentData.studentProfile.level)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.accent)
                    Text("\(studentData.studentProfile.experiencePoints) XP")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Test of the Day Card
    private var testOfTheDayCard: some View {
        Button(action: {
            showingDailyChallenge = true
        }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .font(.caption)
                        Text("SATs Practice")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white.opacity(0.85))

                    Text("SPAG Test of the Day")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("5 mixed questions to sharpen your skills")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(AppTheme.Dimensions.cardPadding)
            .background(AppTheme.Gradients.testOfTheDay)
            .cornerRadius(AppTheme.Dimensions.cornerRadiusXLarge)
            .shadow(color: AppTheme.Colors.accentSecondary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Daily Challenge Card
    private var dailyChallengeCard: some View {
        Button(action: {
            showingDailyChallenge = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.circle.fill")
                            .font(.title3)
                            .foregroundColor(.yellow)
                        Text("Daily Challenge")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    Text(challengeManager.isChallengeCompleted ? "Completed! Come back tomorrow." : "Test your skills with today's challenge!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))

                    if challengeManager.dailyChallengeStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(challengeManager.dailyChallengeStreak) day streak")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: challengeManager.isChallengeCompleted ? "checkmark.circle.fill" : "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(AppTheme.Dimensions.cardPadding)
            .background(AppTheme.Gradients.dailyChallenge)
            .cornerRadius(AppTheme.Dimensions.cornerRadiusLarge)
            .shadow(color: AppTheme.Colors.accent.opacity(0.25), radius: 6, x: 0, y: 3)
        }
    }

    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.itemSpacing) {
            Text("Categories")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(SPAGCategory.allCases) { category in
                    CategoryCardView(
                        category: category,
                        progress: getCategoryProgress(category)
                    )
                    .onTapGesture {
                        selectedCategory = category
                    }
                }
            }
        }
    }

    // MARK: - Quick Progress Card
    private var quickProgressCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.itemSpacing) {
            Text("Your Stats")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)

            HStack(spacing: 12) {
                QuickStatPill(
                    title: "Level",
                    value: "\(studentData.studentProfile.level)",
                    icon: "star.fill",
                    color: AppTheme.Colors.xp
                )
                QuickStatPill(
                    title: "XP",
                    value: "\(studentData.studentProfile.experiencePoints)",
                    icon: "bolt.fill",
                    color: AppTheme.Colors.accent
                )
                QuickStatPill(
                    title: "Streak",
                    value: "\(challengeManager.dailyChallengeStreak)",
                    icon: "flame.fill",
                    color: AppTheme.Colors.streak
                )
            }
        }
    }

    // MARK: - Word of the Day Card
    private var wordOfTheDayCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.itemSpacing) {
            HStack {
                Text("Vocabulary Words")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Button(action: {
                    selectedCategory = .vocabulary
                }) {
                    Text("See all")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.accent)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    VocabularyWordCard(word: "benevolent", definition: "Well-meaning and kindly", example: "The benevolent teacher helped every student.")
                    VocabularyWordCard(word: "consequence", definition: "A result or effect of an action", example: "As a consequence, the match was cancelled.")
                    VocabularyWordCard(word: "sufficient", definition: "Enough; adequate", example: "We had sufficient time to finish the test.")
                }
            }
        }
    }

    // MARK: - Settings Content
    private var settingsContent: some View {
        List {
            Section("Profile") {
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.accent.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.Colors.accent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Learner")
                            .font(.headline)
                        Text("Level \(studentData.studentProfile.level) - \(studentData.studentProfile.experiencePoints) XP")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Learning") {
                NavigationLink {
                    AchievementsListView(achievementManager: achievementManager)
                } label: {
                    Label("Achievements", systemImage: "trophy.fill")
                }

                Label("Year Group: 5-6", systemImage: "graduationcap.fill")
                Label("Difficulty: Adaptive", systemImage: "slider.horizontal.3")
            }

            Section("About") {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("2.0")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                HStack {
                    Label("Curriculum", systemImage: "book.fill")
                    Spacer()
                    Text("UK KS2 SATs")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Helper Methods
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning!"
        case 12..<17: return "Good Afternoon!"
        default: return "Good Evening!"
        }
    }

    private func getCategoryProgress(_ category: SPAGCategory) -> Double {
        let categoryTopics = studentData.performanceHistory.filter { $0.key.contains(category.rawValue) }
        guard !categoryTopics.isEmpty else { return 0 }
        let totalScore = categoryTopics.values.reduce(0.0) { $0 + $1.averageScore }
        return totalScore / Double(categoryTopics.count)
    }
}

// MARK: - Category Card View
struct CategoryCardView: View {
    let category: SPAGCategory
    let progress: Double

    var body: some View {
        VStack(spacing: 12) {
            // Icon with progress ring
            ZStack {
                Circle()
                    .stroke(category.color.opacity(0.15), lineWidth: 4)
                    .frame(width: 56, height: 56)

                if progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress / 100)
                        .stroke(category.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                }

                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(category.color)
                }
            }

            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text("\(category.topics.count) topics")
                .font(.caption2)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.Dimensions.cornerRadiusLarge)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Quick Stat Pill
struct QuickStatPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text(title)
                .font(.caption2)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Vocabulary Word Card
struct VocabularyWordCard: View {
    let word: String
    let definition: String
    let example: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(word)
                .font(.headline)
                .foregroundColor(AppTheme.Colors.vocabulary)

            Text(definition)
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text("\"\(example)\"")
                .font(.caption2)
                .italic()
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineLimit(2)
        }
        .frame(width: 180, alignment: .leading)
        .padding(AppTheme.Dimensions.cardPadding)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    ContentView()
}
