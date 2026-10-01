import Foundation
import SwiftData
import SwiftUI

/// The grown-ups area of SPAG Buddy Home. Always shown inside `GrownUpGateView`.
struct GrownUpsView: View {
    private enum Route: Hashable {
        case child(UUID)
        case addChild
        case data
    }

    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PupilProfile.createdAt) private var children: [PupilProfile]
    @State private var path: [Route] = []
    @State private var confirmingDeleteEverything = false
    @State private var failed = false

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                childrenSection
                dataSection
                schoolSection
                deleteSection
            }
            .navigationTitle("Grown-ups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .child(let id): ChildSummaryView(childID: id)
                case .addChild: ChildFormView()
                case .data: HomeDataView()
                }
            }
            .alert("Delete everything on this iPad?", isPresented: $confirmingDeleteEverything) {
                Button("Delete everything", role: .destructive, action: deleteEverything)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes \(childCount(children.count)), all their progress and all SPAG Buddy settings. There is no copy anywhere else, so it cannot be undone.")
            }
            .alert("Something went wrong", isPresented: $failed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("SPAG Buddy could not delete the data. Please try again.")
            }
        }
    }

    private var childrenSection: some View {
        Section {
            ForEach(children) { child in
                NavigationLink(value: Route.child(child.id)) {
                    HStack(spacing: 14) {
                        AvatarView(avatar: app.content.avatar(key: child.avatarKey), size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(child.displayName).font(.headline)
                            Text("Year \(child.yearGroup) · \(answeredText(child.attempts.count))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityHint("Shows \(child.displayName)'s progress")
            }
            if HomeFamily.canAddChild(existingCount: children.count) {
                NavigationLink(value: Route.addChild) {
                    Label("Add a child", systemImage: "person.badge.plus")
                }
            }
        } header: {
            Text("Children and progress")
        } footer: {
            Text(HomeFamily.canAddChild(existingCount: children.count)
                 ? "Tap a child to see their progress by topic. You can add up to \(HomeFamily.maxChildren) children."
                 : "This iPad has \(HomeFamily.maxChildren) children, the most SPAG Buddy Home allows. Remove a child to add someone new.")
        }
    }

    private var dataSection: some View {
        Section {
            NavigationLink(value: Route.data) {
                Label("Where is my child's data?", systemImage: "lock.shield.fill")
            }
            Link(destination: HomeLinks.privacyPolicy) {
                externalLinkLabel("Privacy policy", systemImage: "hand.raised.fill")
            }
        } header: {
            Text("Your child's data")
        } footer: {
            Text(HomeDataNotice.headline)
        }
    }

    private var schoolSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("Home progress stays on this iPad", systemImage: "ipad")
                    .font(.headline)
                Text("SPAG Buddy Home and SPAG Buddy School are separate apps. Home progress cannot be transferred to SPAG Buddy School, because Home never sends anything off this iPad. There is no copy anywhere else to move.")
                Text("If your child's school uses SPAG Buddy School, your child starts there with a login card from their teacher.")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)

            Link(destination: HomeLinks.spagBuddySchool) {
                externalLinkLabel(
                    "Is your child's school using SPAG Buddy? Find out about SPAG Buddy School",
                    systemImage: "building.columns.fill"
                )
            }
        } header: {
            Text("SPAG Buddy School")
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                confirmingDeleteEverything = true
            } label: {
                Label("Delete everything", systemImage: "trash.fill")
            }
            .disabled(children.isEmpty)
        } footer: {
            Text("Removes every child, all their progress and all SPAG Buddy settings from this iPad. To delete one child's progress, tap the child above.")
        }
    }

    private func externalLinkLabel(_ title: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Image(systemName: "arrow.up.forward.square")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .accessibilityHint("Opens in Safari")
    }

    private func answeredText(_ count: Int) -> String {
        count == 1 ? "1 question answered" : "\(count) questions answered"
    }

    private func childCount(_ count: Int) -> String {
        count == 1 ? "1 child" : "\(count) children"
    }

    private func deleteEverything() {
        path = []
        app.activePupilID = nil
        do {
            try HomeDataEraser.deleteEverything(in: modelContext)
            dismiss()
        } catch {
            failed = true
        }
    }
}

#Preview {
    GrownUpsView()
        .environment(AppModel.preview)
        .modelContainer(.preview)
}
