import Foundation
import SwiftData
import SwiftUI

struct PracticeLaunch: Identifiable {
    let id = UUID()
    var mode: SessionMode
    var title: String
}

struct HomeView: View {
    @Bindable var pupil: PupilProfile
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme
    @Environment(\.edition) private var edition
    @State private var launch: PracticeLaunch?
    @State private var showingSettings = false
    @State private var showingGrownUps = false

    private var streak: Int { StreakCalculator.displayed(pupil.streak, now: .now) }

    private var openAssignments: [Assignment] {
        pupil.assignments
            .filter { $0.completedAt == nil }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    BuddySays(text: greeting, mood: .happy)
                    dailyCard
                    if !openAssignments.isEmpty { assignmentsSection }
                    strandsSection
                    spellingListsSection
                    if pupil.yearGroup >= 6 { satsCard }
                }
                .padding(20)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .screenBackground()
            .navigationTitle(edition.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .refreshable { await app.classServices?.syncNow(pupil: pupil) }
        }
        .fullScreenCover(item: $launch) { launch in
            PracticeSessionView(pupil: pupil, mode: launch.mode, title: launch.title)
                .environment(\.appTheme, theme)
        }
        .sheet(isPresented: $showingSettings) {
            PupilSettingsView(pupil: pupil)
                .environment(\.appTheme, theme)
        }
        .sheet(isPresented: $showingGrownUps) {
            TeacherGateView {
                GrownUpSettingsView(pupil: pupil)
            }
            .environment(\.appTheme, theme)
        }
        .task { await app.classServices?.syncNow(pupil: pupil) }
    }

    private var greeting: String {
        if streak >= 2 { return "\(streak) days in a row, \(pupil.displayName)! Keep it going!" }
        if pupil.sessionsCompleted == 0 { return "Hello, \(pupil.displayName)! Let's start with today's practice." }
        return "Welcome back, \(pupil.displayName)! Ready to practise?"
    }

    private var header: some View {
        HStack(spacing: 12) {
            AvatarView(avatar: app.content.avatar(key: pupil.avatarKey), size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(pupil.displayName).pupilText(.title2, weight: .heavy)
                Text(pupil.className ?? "Year \(pupil.yearGroup)")
                    .pupilText(.subheadline)
                    .foregroundStyle(theme.secondaryText)
            }
            Spacer()
            StatPill(systemImage: "flame.fill", value: "\(streak)", label: "day streak", color: theme.tryAgain)
            StatPill(systemImage: "star.fill", value: "\(pupil.stars)", label: "stars", color: theme.star)
        }
    }

    private var dailyCard: some View {
        Button {
            launch = PracticeLaunch(mode: .daily, title: "Today's practice")
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(theme.star)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's practice").pupilText(.title2, weight: .heavy).foregroundStyle(theme.onPrimary)
                    Text("\(SessionMode.daily.defaultLength) questions · about 5 minutes")
                        .pupilText(.subheadline)
                        .foregroundStyle(theme.onPrimary.opacity(0.9))
                }
                Spacer()
                Image(systemName: "play.circle.fill").font(.system(size: 44)).foregroundStyle(theme.onPrimary)
            }
            .padding(22)
            .background(theme.primaryFill, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Starts \(SessionMode.daily.defaultLength) mixed questions")
    }

    private var assignmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("From your teacher", systemImage: "envelope.open.fill")
            ForEach(openAssignments) { assignment in
                Button {
                    launch = PracticeLaunch(mode: assignment.mode, title: assignment.title)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(assignment.title).pupilText(.headline, weight: .bold)
                            if let due = assignment.dueDate {
                                Text("Due \(due.formatted(.dateTime.weekday(.wide).day().month(.wide)))")
                                    .pupilText(.subheadline)
                                    .foregroundStyle(theme.secondaryText)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(theme.secondaryText)
                    }
                    .card(padding: 16)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var strandsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Choose a topic", systemImage: "square.grid.2x2.fill")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Strand.allCases) { strand in
                    Button {
                        launch = PracticeLaunch(mode: .strand(strand), title: strand.title)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: strand.symbolName)
                                .font(.system(size: 30))
                                .foregroundStyle(theme.color(for: strand))
                            Text(strand.title).pupilText(.title3, weight: .bold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
                        .card(padding: 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var spellingListsSection: some View {
        let lists = app.content.spellingLists(forYear: pupil.yearGroup)
        return VStack(alignment: .leading, spacing: 12) {
            if !lists.isEmpty {
                sectionTitle("Spelling lists", systemImage: "list.bullet.rectangle.fill")
                ForEach(lists) { list in
                    Button {
                        launch = PracticeLaunch(mode: .spellingList(list.id), title: list.title)
                    } label: {
                        HStack {
                            Image(systemName: "ear.fill").foregroundStyle(theme.color(for: .spelling))
                            Text(list.title).pupilText(.headline, weight: .bold)
                            Spacer()
                            Text("\(list.words.count) words").pupilText(.subheadline).foregroundStyle(theme.secondaryText)
                        }
                        .card(padding: 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var satsCard: some View {
        Button {
            launch = PracticeLaunch(mode: .satsPractice, title: "SATs practice")
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "doc.text.fill").font(.system(size: 34)).foregroundStyle(theme.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("SATs practice paper").pupilText(.headline, weight: .bold)
                    Text("10 test-style questions. You'll see your answers at the end.")
                        .pupilText(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                }
                Spacer()
            }
            .card(padding: 16)
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .pupilText(.title3, weight: .bold)
            .accessibilityAddTraits(.isHeader)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                app.activePupilID = nil
            } label: {
                Label("Switch pupil", systemImage: "person.2.fill")
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            NavigationLink {
                PupilProgressView(pupil: pupil)
            } label: {
                Label("My progress", systemImage: "chart.bar.fill")
            }
            Button {
                showingSettings = true
            } label: {
                Label("My settings", systemImage: "textformat.size")
            }
            Button {
                showingGrownUps = true
            } label: {
                Label("Grown-ups", systemImage: "lock.fill")
            }
        }
    }
}

#if DEBUG
#Preview("Home, light") {
    RootView().environment(AppModel.preview).environment(\.edition, .home).modelContainer(.preview)
}

#Preview("Home, dark") {
    RootView().environment(AppModel.preview).environment(\.edition, .home).modelContainer(.preview)
        .preferredColorScheme(.dark)
}

#Preview("School, light") {
    RootView().environment(AppModel.preview).environment(\.edition, .school).modelContainer(.preview)
}

#Preview("School, dark") {
    RootView().environment(AppModel.preview).environment(\.edition, .school).modelContainer(.preview)
        .preferredColorScheme(.dark)
}
#endif
