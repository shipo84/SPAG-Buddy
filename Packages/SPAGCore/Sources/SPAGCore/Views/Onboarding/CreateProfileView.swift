import Foundation
import SwiftData
import SwiftUI

/// Home practice profile. Everything stays on the device.
struct CreateProfileView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var yearGroup: Int?
    @State private var avatarKey: String?

    private var trimmedName: String { String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(20)) }
    private var canStart: Bool { !trimmedName.isEmpty && yearGroup != nil && avatarKey != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                section("What should I call you?") {
                    TextField("First name or nickname", text: $name)
                        .textContentType(.nickname)
                        .autocorrectionDisabled()
                        .pupilText(.title2, weight: .semibold)
                        .padding(16)
                        .background(theme.card, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.cardBorder, lineWidth: theme.borderWidth))
                    Text("Just your first name or a nickname. No surnames, please.")
                        .pupilText(.footnote)
                        .foregroundStyle(theme.secondaryText)
                }

                section("Which year are you in?") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(1...6, id: \.self) { year in
                            Button {
                                yearGroup = year
                            } label: {
                                Text("Year \(year)")
                                    .pupilText(.title3, weight: .bold)
                                    .foregroundStyle(yearGroup == year ? theme.onPrimary : theme.text)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .background(yearGroup == year ? theme.primaryFill : theme.card, in: RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.cardBorder, lineWidth: theme.borderWidth))
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(yearGroup == year ? .isSelected : [])
                        }
                    }
                }

                section("Pick your picture") {
                    AvatarGrid(avatars: app.content.avatars, selection: $avatarKey)
                }

                Button("Let's go!", action: create)
                    .buttonStyle(.big)
                    .disabled(!canStart)
            }
            .padding(24)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .navigationTitle("Practise at home")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).pupilText(.title2, weight: .bold)
            content()
        }
    }

    private func create() {
        guard let yearGroup, let avatarKey, !trimmedName.isEmpty else { return }
        let pupil = PupilProfile(displayName: trimmedName, avatarKey: avatarKey, yearGroup: yearGroup)
        modelContext.insert(pupil)
        try? modelContext.save()
        app.activePupilID = pupil.id
        dismiss()
    }
}
