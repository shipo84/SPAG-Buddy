import Foundation
import SwiftUI

/// "What happens to my answers?" The pupil privacy notice, with a read-aloud button.
struct MyDataView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 16) {
                    BuddyView(mood: .happy, size: 72)
                    Text("Here is what happens to your answers.")
                        .pupilText(.title3, weight: .semibold)
                }

                Button {
                    app.speech.speak(PrivacyNotice.spokenText)
                } label: {
                    Label("Read this to me", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.big)
                .frame(maxWidth: 360)

                ForEach(PrivacyNotice.sections) { section in
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
            }
            .padding(24)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .navigationTitle("My answers")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { app.speech.stop() }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        MyDataView()
    }
    .environment(AppModel.preview)
}
#endif
