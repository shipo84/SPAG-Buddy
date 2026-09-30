import Foundation
import SwiftUI

/// "Who is practising?" for shared classroom iPads.
struct PupilPickerView: View {
    var pupils: [PupilProfile]
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme
    @State private var addingPupil = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    BuddySays(text: "Who is practising today?")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 16)], spacing: 16) {
                        ForEach(pupils) { pupil in
                            Button {
                                app.activePupilID = pupil.id
                            } label: {
                                VStack(spacing: 8) {
                                    AvatarView(avatar: app.content.avatar(key: pupil.avatarKey), size: 80)
                                    Text(pupil.displayName)
                                        .pupilText(.headline, weight: .bold)
                                        .lineLimit(1)
                                    Text("Year \(pupil.yearGroup)")
                                        .pupilText(.caption)
                                        .foregroundStyle(theme.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .card(padding: 16)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(pupil.displayName), Year \(pupil.yearGroup)")
                        }
                    }
                    Button {
                        addingPupil = true
                    } label: {
                        Label("Someone new", systemImage: "plus")
                    }
                    .buttonStyle(.big(theme.secondaryText))
                    .frame(maxWidth: 320)
                }
                .padding(24)
            }
            .screenBackground()
            .navigationTitle("SPAG Buddy")
        }
        .sheet(isPresented: $addingPupil) {
            WelcomeView(showsCancel: true)
        }
    }
}
