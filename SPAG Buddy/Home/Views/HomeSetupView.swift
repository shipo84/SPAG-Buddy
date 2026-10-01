import Foundation
import SwiftData
import SwiftUI

/// First-run set-up for a parent: add up to four children, then hand the iPad over.
struct HomeSetupView: View {
    var onFinish: () -> Void

    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Query(sort: \PupilProfile.createdAt) private var children: [PupilProfile]
    @State private var removing: PupilProfile?

    private var canAddChild: Bool { HomeFamily.canAddChild(existingCount: children.count) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    BuddyView(mood: .cheering, size: 120)
                        .padding(.top, 24)

                    VStack(spacing: 8) {
                        Text(children.isEmpty ? "Welcome to SPAG Buddy" : "Who will practise on this iPad?")
                            .pupilText(.largeTitle, weight: .heavy)
                        Text(children.isEmpty
                             ? "Spelling, punctuation and grammar practice for Years 1 to 6."
                             : "Add everyone who will use SPAG Buddy here. You can add up to \(HomeFamily.maxChildren) children.")
                            .pupilText(.title3)
                            .foregroundStyle(theme.secondaryText)
                    }
                    .multilineTextAlignment(.center)

                    if children.isEmpty {
                        promises
                    } else {
                        childList
                    }

                    VStack(spacing: 12) {
                        if canAddChild {
                            NavigationLink {
                                ChildFormView()
                            } label: {
                                Label(children.isEmpty ? "Add a child" : "Add another child", systemImage: "person.badge.plus")
                            }
                            .buttonStyle(.big(children.isEmpty ? theme.primary : theme.secondaryText))
                        } else {
                            Text("That's \(HomeFamily.maxChildren) children, the most SPAG Buddy Home allows on one iPad.")
                                .pupilText(.footnote)
                                .foregroundStyle(theme.secondaryText)
                                .multilineTextAlignment(.center)
                        }

                        if !children.isEmpty {
                            Button("Start practising", action: onFinish)
                                .buttonStyle(.big(theme.correct))
                        }
                    }
                    .frame(maxWidth: 480)

                    NavigationLink {
                        HomeDataView()
                    } label: {
                        Label("Where is my child's data?", systemImage: "lock.shield.fill")
                            .pupilText(.callout, weight: .semibold)
                    }
                }
                .padding(24)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .screenBackground()
            .alert(
                "Remove \(removing?.displayName ?? "this child")?",
                isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } })
            ) {
                Button("Remove", role: .destructive) {
                    if let removing { try? HomeDataEraser.deleteChild(removing, in: modelContext) }
                    removing = nil
                }
                Button("Cancel", role: .cancel) { removing = nil }
            }
        }
    }

    private var promises: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("For grown-ups")
                .pupilText(.headline, weight: .bold)
                .accessibilityAddTraits(.isHeader)
            promise("person.2.fill", "Add up to \(HomeFamily.maxChildren) children. Just a first name or nickname and a picture.")
            promise("checkmark.shield.fill", "No accounts, no email addresses, no passwords.")
            promise("ipad", HomeDataNotice.headline)
        }
        .frame(maxWidth: 480, alignment: .leading)
        .card()
    }

    private func promise(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(theme.primary)
                .frame(width: 30)
                .accessibilityHidden(true)
            Text(text)
                .pupilText(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var childList: some View {
        VStack(spacing: 12) {
            ForEach(children) { child in
                HStack(spacing: 14) {
                    AvatarView(avatar: app.content.avatar(key: child.avatarKey), size: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(child.displayName).pupilText(.title3, weight: .bold)
                        Text("Year \(child.yearGroup)").pupilText(.subheadline).foregroundStyle(theme.secondaryText)
                    }
                    Spacer()
                    Button {
                        removing = child
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(child.displayName)")
                }
                .card(padding: 14)
            }
        }
        .frame(maxWidth: 480)
    }
}

#Preview {
    HomeSetupView(onFinish: {})
        .environment(AppModel.preview)
        .modelContainer(.preview)
}
