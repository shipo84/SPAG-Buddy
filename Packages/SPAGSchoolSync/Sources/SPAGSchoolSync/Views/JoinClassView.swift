import Foundation
import SPAGCore
import SwiftData
import SwiftUI

/// Joining a class with the pupil's login card: scan its QR code, or type the class code, tap the picture and enter the 4-digit PIN.
struct JoinClassView: View {
    var prefilled: JoinDetails?

    private enum Step { case classCode, picture, pin }

    @Environment(AppModel.self) private var app
    @Environment(SchoolClassServices.self) private var classServices
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
    @State private var scanning = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let notice = classServices.session.notice, prefilled == nil {
                    BuddySays(text: notice.message, mood: .thinking)
                }

                if classServices.api == nil {
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

                if prefilled == nil {
                    NavigationLink {
                        SchoolPrivacyNoticeView()
                    } label: {
                        Label("What happens to my answers?", systemImage: "lock.shield.fill")
                            .pupilText(.callout, weight: .semibold)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .navigationTitle("Join your class")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if prefilled != nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $scanning) {
            LoginCardScannerSheet { details in
                scanning = false
                Task { await join(with: details) }
            }
        }
        .task {
            guard let prefilled else { return }
            await join(with: prefilled)
        }
    }

    private var classCodeStep: some View {
        VStack(spacing: 20) {
            BuddySays(text: "Scan the code on your login card, or type your class code.")
            Button {
                message = nil
                scanning = true
            } label: {
                Label("Scan my login card", systemImage: "qrcode.viewfinder")
            }
            .buttonStyle(.big)

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
            .buttonStyle(.big(theme.correct))
            .disabled(classCode.count != 6)
        }
    }

    private var pictureStep: some View {
        VStack(spacing: 20) {
            BuddySays(text: "Now tap your picture. It is on your card.")
            AvatarGrid(avatars: app.content.avatars, selection: $avatarKey, size: 64)
            HStack(spacing: 12) {
                Button("Back") { step = .classCode }
                    .buttonStyle(.big(theme.secondaryText))
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
                .buttonStyle(.big(theme.secondaryText))
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

    private func join(with details: JoinDetails) async {
        classCode = details.classCode
        avatarKey = details.avatarKey
        pin = details.pin
        await join(fromCard: true)
    }

    private func join(fromCard: Bool = false) async {
        guard let api = classServices.api, let avatarKey, !isJoining else { return }
        isJoining = true
        message = nil
        defer { isJoining = false }

        do {
            let response = try await api.join(classCode: classCode, avatarKey: avatarKey, pin: pin)
            try classServices.completeJoin(response, existing: pupils, context: modelContext)
            dismiss()
        } catch APIError.tooManyAttempts {
            message = "Too many tries. Ask your teacher for help."
            pin = ""
        } catch APIError.notFound, APIError.unauthorised {
            message = fromCard
                ? "That card didn't work. Ask your teacher for a new login card."
                : "That didn't work. Check your class code, picture and number, then try again."
            pin = ""
            step = fromCard ? .classCode : .pin
        } catch is APIError {
            message = "I couldn't reach the internet. Try again in a moment."
        } catch {
            message = "Something went wrong on this iPad. Try again, or ask your teacher."
        }
    }
}
