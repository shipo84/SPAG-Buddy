import Foundation
import SwiftData
import SwiftUI

struct GrownUpSettingsView: View {
    @Bindable var pupil: PupilProfile
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Pupil") {
                    LabeledContent("Name", value: pupil.displayName)
                    Picker("Year group", selection: $pupil.yearGroup) {
                        ForEach(1...6, id: \.self) { Text("Year \($0)").tag($0) }
                    }
                    LabeledContent("Questions answered", value: "\(pupil.attempts.count)")
                }

                Section {
                    Label(AppInfo.name, systemImage: "house.fill")
                    Text("Nothing is sent anywhere. All answers stay on this iPad and are never synced to iCloud.")
                } header: {
                    Text("Privacy")
                }

                Section {
                    Button("Remove \(pupil.displayName) from this iPad", role: .destructive) {
                        confirmingDelete = true
                    }
                } footer: {
                    Text("This permanently deletes this pupil's progress.")
                }
            }
            .navigationTitle("Grown-ups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Remove \(pupil.displayName)?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Remove", role: .destructive, action: remove)
            } message: {
                Text("All of \(pupil.displayName)'s stars, stickers and answers will be deleted.")
            }
        }
    }

    private func remove() {
        if app.activePupilID == pupil.id { app.activePupilID = nil }
        modelContext.delete(pupil)
        try? modelContext.save()
        dismiss()
    }
}
