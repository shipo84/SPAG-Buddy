import Foundation
import SwiftData
import SwiftUI

/// One child's progress by topic, written so a parent can show it to the child. Grown-up options are at the bottom.
struct ChildSummaryView: View {
    @Query private var matches: [PupilProfile]

    init(childID: UUID) {
        _matches = Query(filter: #Predicate<PupilProfile> { $0.id == childID })
    }

    var body: some View {
        if let child = matches.first {
            ChildSummaryContent(child: child)
                .environment(\.appTheme, AppTheme(pupil: child))
        } else {
            ContentUnavailableView("This child has been removed", systemImage: "person.crop.circle.badge.xmark")
        }
    }
}

private struct ChildSummaryContent: View {
    @Bindable var child: PupilProfile
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDeleteProgress = false
    @State private var confirmingRemove = false
    @State private var failed = false

    private var topics: [TopicSummary] {
        HomeProgressSummary.topics(
            objectives: Array(app.content.objectives.values),
            attempts: child.attemptRecords,
            yearGroup: child.yearGroup
        )
    }

    var body: some View {
        let topics = topics
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                totals(answered: topics.map(\.answered).reduce(0, +))

                Text("Topics")
                    .pupilText(.title2, weight: .heavy)
                    .accessibilityAddTraits(.isHeader)
                ForEach(topics) { topic in
                    TopicCard(topic: topic)
                }

                legend
                grownUpOptions
            }
            .padding(20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .navigationTitle(child.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: child.yearGroup) { _, _ in try? modelContext.save() }
        .alert("Delete \(child.displayName)'s progress?", isPresented: $confirmingDeleteProgress) {
            Button("Delete progress", role: .destructive, action: deleteProgress)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All answers, stars, stickers and streaks for \(child.displayName) will be deleted from this iPad. The name and picture stay, so they can start again. This cannot be undone.")
        }
        .alert("Remove \(child.displayName) from this iPad?", isPresented: $confirmingRemove) {
            Button("Remove", role: .destructive, action: remove)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes \(child.displayName)'s profile and all of their progress. There is no copy anywhere else, so it cannot be undone.")
        }
        .alert("Something went wrong", isPresented: $failed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("SPAG Buddy could not delete the data. Please try again.")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            AvatarView(avatar: app.content.avatar(key: child.avatarKey), size: 80)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(child.displayName)'s progress").pupilText(.largeTitle, weight: .heavy)
                Text("Year \(child.yearGroup)").pupilText(.title3).foregroundStyle(theme.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func totals(answered: Int) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            SummaryTile(systemImage: "star.fill", value: "\(child.stars)", label: "stars", color: theme.star)
            SummaryTile(
                systemImage: "flame.fill",
                value: "\(StreakCalculator.displayed(child.streak, now: .now))",
                label: "day streak",
                color: theme.tryAgain
            )
            SummaryTile(systemImage: "checkmark.circle.fill", value: "\(answered)", label: "questions answered", color: theme.correct)
            SummaryTile(
                systemImage: "seal.fill",
                value: "\(child.badges.count) of \(BadgeRules.all.count)",
                label: "stickers",
                color: theme.primary
            )
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What the colours mean")
                .pupilText(.headline, weight: .bold)
                .accessibilityAddTraits(.isHeader)
            ForEach(MasteryLevel.summaryOrder, id: \.self) { level in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Circle().fill(theme.color(for: level)).frame(width: 12, height: 12).accessibilityHidden(true)
                    Text("**\(level.childLabel):** \(level.parentExplanation)")
                }
                .pupilText(.subheadline)
            }
        }
        .card()
    }

    private var grownUpOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Grown-up options")
                .pupilText(.title3, weight: .bold)
                .accessibilityAddTraits(.isHeader)

            HStack {
                Text("School year").pupilText(.body, weight: .semibold)
                Spacer()
                Picker("School year", selection: $child.yearGroup) {
                    ForEach(1...6, id: \.self) { Text("Year \($0)").tag($0) }
                }
                .pickerStyle(.menu)
            }

            Button(role: .destructive) {
                confirmingDeleteProgress = true
            } label: {
                Label("Delete \(child.displayName)'s progress", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(child.attempts.isEmpty && child.badges.isEmpty && child.stars == 0)

            Button(role: .destructive) {
                confirmingRemove = true
            } label: {
                Label("Remove \(child.displayName) from this iPad", systemImage: "person.crop.circle.badge.minus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .card()
    }

    private func deleteProgress() {
        do {
            try HomeDataEraser.deleteProgress(of: child, in: modelContext)
        } catch {
            failed = true
        }
    }

    private func remove() {
        if app.activePupilID == child.id { app.activePupilID = nil }
        do {
            try HomeDataEraser.deleteChild(child, in: modelContext)
            dismiss()
        } catch {
            failed = true
        }
    }
}

private struct TopicCard: View {
    var topic: TopicSummary
    @Environment(\.appTheme) private var theme
    @State private var showingSkills = false

    private var score: String {
        topic.answered == 0 ? "Not tried yet" : "\(topic.correct) of \(topic.answered) right"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(topic.strand.title, systemImage: topic.strand.symbolName)
                    .pupilText(.title3, weight: .bold)
                    .foregroundStyle(theme.color(for: topic.strand))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(score)
                    .pupilText(.subheadline, weight: .semibold)
                    .foregroundStyle(theme.secondaryText)
            }

            LevelBar(topic: topic)

            FlowLayout(spacing: 14, lineSpacing: 6) {
                ForEach(MasteryLevel.summaryOrder, id: \.self) { level in
                    let count = topic.count(level)
                    if count > 0 {
                        HStack(spacing: 6) {
                            Circle().fill(theme.color(for: level)).frame(width: 10, height: 10)
                            Text("\(level.childLabel): \(count)").pupilText(.subheadline)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(count) \(count == 1 ? "skill" : "skills") \(level.childLabel)")
                    }
                }
            }

            DisclosureGroup(isExpanded: $showingSkills) {
                VStack(spacing: 10) {
                    ForEach(topic.skills) { skill in
                        SkillRow(skill: skill)
                    }
                }
                .padding(.top, 8)
            } label: {
                Text(showingSkills ? "Hide skills" : "See each skill (\(topic.skills.count))")
                    .pupilText(.subheadline, weight: .semibold)
            }
        }
        .card()
    }
}

private struct LevelBar: View {
    var topic: TopicSummary
    @Environment(\.appTheme) private var theme

    var body: some View {
        let total = max(topic.skills.count, 1)
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(MasteryLevel.summaryOrder, id: \.self) { level in
                    Rectangle()
                        .fill(theme.color(for: level))
                        .frame(width: proxy.size.width * CGFloat(topic.count(level)) / CGFloat(total))
                }
            }
        }
        .frame(height: 14)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

private struct SkillRow: View {
    var skill: TopicSummary.Skill
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.objective.childTitle).pupilText(.headline, weight: .bold)
                Text(skill.stats.level.childLabel)
                    .pupilText(.subheadline)
                    .foregroundStyle(theme.color(for: skill.stats.level))
            }
            Spacer()
            if skill.stats.attempts > 0 {
                Text("\(skill.stats.correct) of \(skill.stats.attempts)")
                    .pupilText(.caption)
                    .foregroundStyle(theme.secondaryText)
            }
            MasteryDots(level: skill.stats.level, color: theme.color(for: skill.stats.level))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let base = "\(skill.objective.childTitle). \(skill.stats.level.childLabel)."
        return skill.stats.attempts == 0 ? base : "\(base) \(skill.stats.correct) of \(skill.stats.attempts) right."
    }
}

private struct SummaryTile: View {
    var systemImage: String
    var value: String
    var label: String
    var color: Color
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage).font(.title2).foregroundStyle(color)
            Text(value).pupilText(.title, weight: .heavy)
            Text(label).pupilText(.subheadline).foregroundStyle(theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}

private extension MasteryLevel {
    static let summaryOrder: [MasteryLevel] = [.secure, .developing, .needsSupport, .notStarted]

    var parentExplanation: String {
        switch self {
        case .secure:
            "practised at least \(MasteryLevel.minimumAttemptsForSecure) times, with \(Int(MasteryLevel.secureAccuracy * 10)) in 10 recent answers right."
        case .developing:
            "practising and on the way."
        case .needsSupport:
            "fewer than half of recent answers right. Short, regular practice helps most."
        case .notStarted:
            "no questions on this skill yet."
        }
    }
}

private extension AppTheme {
    func color(for level: MasteryLevel) -> Color {
        switch level {
        case .notStarted: secondaryText.opacity(0.35)
        case .needsSupport: tryAgain
        case .developing: primary
        case .secure: correct
        }
    }
}
