import Foundation
import SwiftUI

/// Settings a pupil can change themselves. Accessibility is never locked behind a grown-up check.
struct PupilSettingsView: View {
    @Bindable var pupil: PupilProfile
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $pupil.easyReadText) {
                        Label("Easy-read text", systemImage: "textformat.size")
                    }
                    Toggle(isOn: $pupil.highContrast) {
                        Label("Strong colours", systemImage: "circle.lefthalf.filled")
                    }
                    Toggle(isOn: $pupil.autoReadAloud) {
                        Label("Read questions to me", systemImage: "speaker.wave.2.fill")
                    }
                } footer: {
                    Text("Easy-read text adds more space between letters and lines. You can also make text bigger in the iPad's Settings.")
                }

                Section("Try it") {
                    Text("The quick brown fox jumps over the lazy dog.")
                        .pupilText(.title3)
                    Button("Say it") {
                        app.speech.speak("The quick brown fox jumps over the lazy dog.")
                    }
                }

                Section {
                    NavigationLink {
                        MyDataView()
                    } label: {
                        Label("What happens to my answers?", systemImage: "lock.shield.fill")
                    }
                }
            }
            .navigationTitle("My settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .environment(\.appTheme, AppTheme(pupil: pupil, edition: app.edition))
    }
}
