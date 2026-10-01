import Foundation
import SwiftUI

struct PupilProgressView: View {
    var pupil: PupilProfile
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme
    @State private var launch: PracticeLaunch?

    private var stats: [String: ObjectiveStats] { ProgressCalculator.objectiveStats(from: pupil.attemptRecords) }

    private var objectives: [Objective] {
        let years = max(1, pupil.yearGroup - 1)...pupil.yearGroup
        return app.content.objectives.values
            .filter { years.contains($0.yearGroup) }
            .sorted { ($0.yearGroup, $0.strand.rawValue, $0.code) > ($1.yearGroup, $1.strand.rawValue, $1.code) }
    }

    var body: some View {
        let stats = stats
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                stickers
                ForEach(Strand.allCases) { strand in
                    let items = objectives.filter { $0.strand == strand }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(strand.title, systemImage: strand.symbolName)
                                .pupilText(.title3, weight: .bold)
                                .foregroundStyle(theme.color(for: strand))
                                .accessibilityAddTraits(.isHeader)
                            ForEach(items) { objective in
                                row(objective, stats: stats[objective.code] ?? ObjectiveStats())
                            }
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .navigationTitle("My progress")
        .fullScreenCover(item: $launch) { launch in
            PracticeSessionView(pupil: pupil, mode: launch.mode, title: launch.title)
                .environment(\.appTheme, theme)
        }
    }

    private var stickers: some View {
        let earned = Set(pupil.badges.map(\.badgeId))
        return VStack(alignment: .leading, spacing: 12) {
            Text("My stickers").pupilText(.title2, weight: .heavy)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
                ForEach(BadgeRules.all) { badge in
                    let has = earned.contains(badge.id)
                    VStack(spacing: 6) {
                        Text(has ? badge.emoji : "❔").font(.system(size: 40)).opacity(has ? 1 : 0.4)
                        Text(badge.title).pupilText(.caption, weight: .bold).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 96)
                    .card(padding: 10)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(has ? "\(badge.title), earned" : "\(badge.title), not earned yet. \(badge.detail)")
                }
            }
        }
    }

    private func row(_ objective: Objective, stats: ObjectiveStats) -> some View {
        Button {
            launch = PracticeLaunch(mode: .objective(objective.code), title: objective.childTitle)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(objective.childTitle).pupilText(.headline, weight: .bold)
                    Text(stats.level.childLabel).pupilText(.subheadline).foregroundStyle(color(for: stats.level))
                }
                Spacer()
                MasteryDots(level: stats.level, color: color(for: stats.level))
                Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(theme.primary)
            }
            .card(padding: 14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(objective.childTitle). \(stats.level.childLabel). Practise this.")
    }

    private func color(for level: MasteryLevel) -> Color {
        switch level {
        case .notStarted: theme.secondaryText
        case .needsSupport: theme.tryAgain
        case .developing: theme.primaryText
        case .secure: theme.correct
        }
    }
}

private struct MasteryDots: View {
    var level: MasteryLevel
    var color: Color
    @Environment(\.appTheme) private var theme

    private var filled: Int {
        switch level {
        case .notStarted: 0
        case .needsSupport: 1
        case .developing: 2
        case .secure: 3
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle().fill(index < filled ? color : theme.text.opacity(0.1)).frame(width: 12, height: 12)
            }
        }
        .accessibilityHidden(true)
    }
}
