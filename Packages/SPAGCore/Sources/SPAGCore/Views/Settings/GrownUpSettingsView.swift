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

    private var unsyncedCount: Int { app.classServices?.unsentCount(for: pupil) ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pupil") {
                    LabeledContent("Name", value: pupil.displayName)
                    if pupil.isInClass {
                        LabeledContent("Year group", value: "Year \(pupil.yearGroup)")
                    } else {
                        Picker("Year group", selection: $pupil.yearGroup) {
                            ForEach(1...6, id: \.self) { Text("Year \($0)").tag($0) }
                        }
                    }
                    LabeledContent("Questions answered", value: "\(pupil.attempts.count)")
                }

                if pupil.isInClass {
                    Section {
                        LabeledContent("Class", value: pupil.className ?? pupil.classCode ?? "")
                        LabeledContent("Waiting to send", value: "\(unsyncedCount) answers")
                        if let last = pupil.lastSyncedAt {
                            LabeledContent("Last sent", value: last.formatted(date: .abbreviated, time: .shortened))
                        }
                        if let error = app.classServices?.lastError {
                            Text(error).foregroundStyle(.orange)
                        }
                        Button {
                            Task {
                                syncing = true
                                await app.classServices?.syncNow(pupil: pupil)
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
                        Text("This pupil is practising at home. Nothing is sent anywhere; all answers stay on this device.")
                    }
                }

                Section {
                    Button("Remove \(pupil.displayName) from this iPad", role: .destructive) {
                        confirmingDelete = true
                    }
                } footer: {
                    Text(pupil.isInClass
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
        app.classServices?.forget(pupil: pupil)
        if app.activePupilID == pupil.id { app.activePupilID = nil }
        modelContext.delete(pupil)
        try? modelContext.save()
        dismiss()
    }
}
