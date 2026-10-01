import Foundation
import SwiftUI

/// "Who is practising?" for the children on this iPad. Adding children is done by a grown-up.
struct HomePickerView: View {
    var children: [PupilProfile]
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme
    @Environment(\.openGrownUps) private var openGrownUps

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    BuddySays(text: "Who is practising today?")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                        ForEach(children) { child in
                            Button {
                                app.activePupilID = child.id
                            } label: {
                                VStack(spacing: 8) {
                                    AvatarView(avatar: app.content.avatar(key: child.avatarKey), size: 96)
                                    Text(child.displayName)
                                        .pupilText(.title3, weight: .bold)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .card(padding: 18)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(child.displayName)
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .screenBackground()
            .navigationTitle("SPAG Buddy")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        openGrownUps?()
                    } label: {
                        Label("Grown-ups", systemImage: "lock.fill")
                    }
                }
            }
        }
    }
}
