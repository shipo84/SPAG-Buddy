import Foundation
import SPAGCore
import SwiftData
import SwiftUI

/// Joining a class with the details on the pupil's login card: class code, picture and 4-digit PIN.
struct JoinClassView: View {
    var prefilled: JoinDetails?

    private enum Step { case classCode, picture, pin }

    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Query private var pupils: [PupilProfile]

    @State private var step: Step = .classCode
    @State private var classCode = ""
    @State private var avatarKey: String?
    @State private var pin = ""
    @State private var isJoining = false
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if APIClient.live == nil {
                    BuddySays(text: "Joining a class is not set up on this iPad yet. Ask your teacher.", mood: .thinking)
                } else {
                    switch step {
                    case .classCode: classCodeStep
                    case .picture: pictureStep
                    case .pin: pinStep
                    }
                }

                if let message {
                    Text(message)
                        .pupilText(.headline, weight: .semibold)
                        .foregroundStyle(theme.tryAgain)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .navigationTitle("Join my class")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if prefilled != nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            guard let prefilled else { return }
            classCode = prefilled.classCode
            avatarKey = prefilled.avatarKey
            pin = prefilled.pin
            await join()
        }
    }

    private var classCodeStep: some View {
        VStack(spacing: 20) {
            BuddySays(text: "Type the class code from your card.")
            TextField("Class code", text: $classCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .multilineTextAlignment(.center)
                .font(.system(size: 40, weight: .heavy, design: .monospaced))
                .padding(16)
                .background(theme.card, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(theme.cardBorder, lineWidth: theme.borderWidth))
                .onChange(of: classCode) { _, newValue in
                    classCode = String(newValue.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
                }
            Button("Next") {
                message = nil
                step = .picture
            }
            .buttonStyle(.big)
            .disabled(classCode.count != 6)
        }
    }

    private var pictureStep: some View {
        VStack(spacing: 20) {
            BuddySays(text: "Now tap your picture. It is on your card.")
            AvatarGrid(avatars: app.content.avatars, selection: $avatarKey, size: 64)
            HStack(spacing: 12) {
                Button("Back") { step = .classCode }
                    .buttonStyle(.big(theme.neutralFill))
                Button("Next") { step = .pin }
                    .buttonStyle(.big)
                    .disabled(avatarKey == nil)
            }
        }
    }

    private var pinStep: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                AvatarView(avatar: avatarKey.flatMap(app.content.avatar(key:)), size: 64)
                Text("Type your secret number.").pupilText(.title3, weight: .semibold)
            }
            PinPad(pin: $pin)
            HStack(spacing: 12) {
                Button("Back") {
                    pin = ""
                    step = .picture
                }
                .buttonStyle(.big(theme.neutralFill))
                Button {
                    Task { await join() }
                } label: {
                    if isJoining { ProgressView().tint(.white) } else { Text("Join") }
                }
                .buttonStyle(.big(theme.correct))
                .disabled(pin.count != 4 || isJoining)
            }
        }
    }

    private func join() async {
        guard let api = APIClient.live, let avatarKey else { return }
        isJoining = true
        message = nil
        defer { isJoining = false }

        do {
            let response = try await api.join(classCode: classCode, avatarKey: avatarKey, pin: pin)
            let pupil: PupilProfile
            if let existing = pupils.first(where: { $0.remotePupilId == response.pupilId }) {
                pupil = existing
            } else {
                pupil = PupilProfile(
                    displayName: response.displayName,
                    avatarKey: response.avatarKey,
                    yearGroup: response.yearGroup,
                    remotePupilId: response.pupilId,
                    classCode: response.classCode,
                    className: response.className
                )
                modelContext.insert(pupil)
            }
            pupil.yearGroup = response.yearGroup
            pupil.className = response.className
            try KeychainStore.saveToken(response.deviceToken, for: pupil.id)
            try? modelContext.save()
            app.activePupilID = pupil.id
            dismiss()
        } catch APIError.tooManyAttempts {
            message = "Too many tries. Ask your teacher for help."
            pin = ""
        } catch APIError.notFound, APIError.unauthorised {
            message = "That didn't work. Check your class code, picture and number, then try again."
            pin = ""
            step = prefilled == nil ? .pin : .classCode
        } catch {
            message = "I couldn't reach the internet. Try again in a moment."
        }
    }
}
