import Foundation
import SPAGCore
import SwiftUI

/// "What happens to my answers?" for pupils in a class. Before the first join it ends with a
/// button to carry on to "Join your class".
struct SchoolPrivacyNoticeView: View {
    /// Set before the first join. `nil` when opened from the join screen to read again.
    var onContinue: (() -> Void)?

    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 16) {
                    BuddyView(mood: .happy, size: 72)
                    Text(onContinue == nil
                         ? "Here is what happens to your answers."
                         : "Before you join your class, here is what happens to your answers.")
                        .pupilText(.title3, weight: .semibold)
                }

                Button {
                    app.speech.speak(SchoolPrivacyNotice.spokenText)
                } label: {
                    Label("Read this to me", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.big)
                .frame(maxWidth: 360)

                ForEach(SchoolPrivacyNotice.sections) { section in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: section.symbol)
                            .font(.title2)
                            .foregroundStyle(theme.primary)
                            .frame(width: 36)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title)
                                .pupilText(.headline, weight: .bold)
                                .accessibilityAddTraits(.isHeader)
                            Text(section.body)
                                .pupilText(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .card()
                }

                Link(destination: SchoolPrivacyNotice.fullNoticeURL) {
                    Label("For grown-ups: read the full privacy notice", systemImage: "safari.fill")
                        .pupilText(.callout, weight: .semibold)
                }

                if let onContinue {
                    Button("I understand. Let's join!", action: onContinue)
                        .buttonStyle(.big(theme.correct))
                }
            }
            .padding(24)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .navigationTitle(onContinue == nil ? "My answers" : "Welcome to SPAG School")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { app.speech.stop() }
    }
}
