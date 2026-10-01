import Foundation
import SwiftData
import SwiftUI

struct GrownUpSettingsView: View {
    @Bindable var pupil: PupilProfile
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false
    @State private var syncing = false

    /// Class pupil in the School edition. Home has no classes, so this is always false there.
    private var inClass: Bool { app.edition.isSchool && pupil.isInClass }
    private var unsyncedCount: Int { inClass ? pupil.attempts.filter(\.needsSync).count : 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pupil") {
                    LabeledContent("Name", value: pupil.displayName)
                    if inClass {
                        LabeledContent("Year group", value: "Year \(pupil.yearGroup)")
                    } else {
                        Picker("Year group", selection: $pupil.yearGroup) {
                            ForEach(1...6, id: \.self) { Text("Year \($0)").tag($0) }
                        }
                    }
                    LabeledContent("Questions answered", value: "\(pupil.attempts.count)")
                }

                if inClass, let sync = app.sync {
                    Section {
                        LabeledContent("Class", value: pupil.className ?? pupil.classCode ?? "")
                        LabeledContent("Waiting to send", value: "\(unsyncedCount) answers")
                        if let last = pupil.lastSyncedAt {
                            LabeledContent("Last sent", value: last.formatted(date: .abbreviated, time: .shortened))
                        }
                        if let error = sync.lastError {
                            Text(error).foregroundStyle(.orange)
                        }
                        Button {
                            Task {
                                syncing = true
                                await sync.syncNow(pupil: pupil)
                                syncing = false
                            }
                        } label: {
                            if syncing { ProgressView() } else { Text("Send work to teacher now") }
                        }
                    } header: {
                        Text("Class")
                    } footer: {
                        Text("Answers are saved on this iPad and sent to the teacher's dashboard when there is an internet connection.")
                    }
                } else {
                    Section {
                        Label(app.edition.displayName, systemImage: app.edition.symbolName)
                        Text("Nothing is sent anywhere. All answers stay on this iPad.")
                    } header: {
                        Text("Privacy")
                    }
                }

                Section {
                    Button("Remove \(pupil.displayName) from this iPad", role: .destructive) {
                        confirmingDelete = true
                    }
                } footer: {
                    Text(inClass
                         ? "This removes the pupil's data from this iPad only. Answers already sent are managed by the school and can be deleted by the teacher."
                         : "This permanently deletes this pupil's progress.")
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
                if unsyncedCount > 0 {
                    Text("\(unsyncedCount) answers have not been sent to the teacher yet and will be lost.")
                }
            }
        }
    }

    private func remove() {
        if app.edition.isSchool { KeychainStore.deleteToken(for: pupil.id) }
        if app.activePupilID == pupil.id { app.activePupilID = nil }
        modelContext.delete(pupil)
        try? modelContext.save()
        dismiss()
    }
}
