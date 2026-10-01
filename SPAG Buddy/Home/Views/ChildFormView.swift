import Foundation
import SwiftData
import SwiftUI

/// A parent adds a child: first name or nickname, picture and school year. No codes, PINs or accounts.
struct ChildFormView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Query private var children: [PupilProfile]

    @State private var name = ""
    @State private var avatarKey: String?
    @State private var yearGroup: Int?

    private var cleanedName: String { HomeFamily.cleanedName(name) }
    private var nameProblem: HomeFamily.NameProblem? {
        HomeFamily.nameProblem(name, existingNames: children.map(\.displayName))
    }
    private var isFull: Bool { !HomeFamily.canAddChild(existingCount: children.count) }
    private var canSave: Bool { nameProblem == nil && avatarKey != nil && yearGroup != nil && !isFull }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if isFull {
                    BuddySays(
                        text: "This iPad already has \(HomeFamily.maxChildren) children. Remove one in Grown-ups to add someone new.",
                        mood: .thinking
                    )
                } else {
                    nameSection
                    section("Pick a picture", footnote: "Your child taps this picture to start practising.") {
                        AvatarGrid(avatars: app.content.avatars, selection: $avatarKey)
                    }
                    yearSection

                    Button(cleanedName.isEmpty ? "Add child" : "Add \(cleanedName)", action: save)
                        .buttonStyle(.big)
                        .disabled(!canSave)
                }
            }
            .padding(24)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .navigationTitle("Add a child")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var nameSection: some View {
        section("First name or nickname", footnote: "No surname needed. Your child will see this name.") {
            TextField("For example, Mia", text: $name)
                .textContentType(.nickname)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .pupilText(.title2, weight: .semibold)
                .padding(16)
                .background(theme.card, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.cardBorder, lineWidth: theme.borderWidth))
            if nameProblem == .alreadyUsed {
                Text("There is already a child called \(cleanedName) on this iPad. Try a nickname or add an initial.")
                    .pupilText(.footnote, weight: .semibold)
                    .foregroundStyle(theme.tryAgain)
            }
        }
    }

    private var yearSection: some View {
        section("Which year are they in at school?", footnote: "SPAG Buddy chooses questions for this year. You can change it later in Grown-ups.") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(1...6, id: \.self) { year in
                    Button {
                        yearGroup = year
                    } label: {
                        Text("Year \(year)")
                            .pupilText(.title3, weight: .bold)
                            .foregroundStyle(yearGroup == year ? theme.onPrimary : theme.text)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(yearGroup == year ? theme.primary : theme.card, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.cardBorder, lineWidth: theme.borderWidth))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(yearGroup == year ? .isSelected : [])
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, footnote: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .pupilText(.title2, weight: .bold)
                .accessibilityAddTraits(.isHeader)
            content()
            Text(footnote)
                .pupilText(.footnote)
                .foregroundStyle(theme.secondaryText)
        }
    }

    private func save() {
        guard canSave, let avatarKey, let yearGroup else { return }
        modelContext.insert(PupilProfile(displayName: cleanedName, avatarKey: avatarKey, yearGroup: yearGroup))
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ChildFormView()
    }
    .environment(AppModel.preview)
    .modelContainer(.preview)
}
