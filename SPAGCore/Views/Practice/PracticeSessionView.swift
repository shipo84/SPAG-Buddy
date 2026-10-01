import Foundation
import SwiftData
import SwiftUI

struct PracticeSessionView: View {
    var pupil: PupilProfile
    var mode: SessionMode
    var title: String

    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var session: PracticeSession?
    @State private var answer: PupilAnswer?
    @State private var confirmingQuit = false

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    content(for: session)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .screenBackground()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if session?.phase == .finished { close() } else { confirmingQuit = true }
                    } label: {
                        Label("Stop", systemImage: "xmark.circle.fill")
                    }
                }
            }
            .confirmationDialog("Stop practising?", isPresented: $confirmingQuit, titleVisibility: .visible) {
                Button("Stop", role: .destructive) { close() }
                Button("Keep going", role: .cancel) {}
            } message: {
                Text("The answers you have given so far are saved.")
            }
        }
        .onAppear {
            if session == nil {
                session = PracticeSession.make(mode: mode, pupil: pupil, library: app.content)
            }
        }
        .onDisappear { app.speech.stop() }
    }

    @ViewBuilder
    private func content(for session: PracticeSession) -> some View {
        switch session.phase {
        case .finished:
            SessionSummaryView(session: session, pupil: pupil, onDone: close)
        case .answering, .feedback:
            if let question = session.current {
                questionScreen(session: session, question: question)
            }
        }
    }

    private func questionScreen(session: PracticeSession, question: Question) -> some View {
        let feedback: MarkResult? = if case .feedback(let result) = session.phase { result } else { nil }

        return VStack(spacing: 0) {
            ProgressView(value: session.progress)
                .tint(theme.primary)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .accessibilityLabel("Question \(session.index + 1) of \(session.questions.count)")

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    QuestionCard(question: question, objective: app.content.objective(code: question.objectiveCode), session: session, pupil: pupil)
                    AnswerInputView(question: question, answer: $answer, locked: feedback != nil)
                    if let feedback {
                        FeedbackPanel(question: question, result: feedback, rule: app.content.objective(code: question.objectiveCode)?.rule)
                    }
                }
                .padding(20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)

            Group {
                if feedback != nil {
                    Button(session.index + 1 < session.questions.count ? "Next question" : "See my score") {
                        answer = nil
                        session.advance(pupil: pupil, context: modelContext)
                    }
                    .buttonStyle(.big)
                } else {
                    Button(mode.givesInstantFeedback ? "Check" : "Next") {
                        guard let answer else { return }
                        session.submit(answer, pupil: pupil, context: modelContext)
                        if !mode.givesInstantFeedback { self.answer = nil }
                    }
                    .buttonStyle(.big(theme.correct))
                    .disabled(!isAnswerReady(for: question))
                }
            }
            .padding(20)
            .frame(maxWidth: 720)
            .sensoryFeedback(trigger: feedback) { _, new in
                guard let new else { return nil }
                return new.correct ? .success : .warning
            }
        }
        .task(id: question.id) {
            if pupil.autoReadAloud || question.type == .spelling {
                app.speech.speak(question.audioText, slowly: pupil.yearGroup <= 2 || question.type == .spelling)
            }
        }
    }

    private func isAnswerReady(for question: Question) -> Bool {
        switch answer {
        case .none: false
        case .choice: true
        case .choices(let set): !set.isEmpty
        case .gaps(let set): !set.isEmpty
        case .text(let text): !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func close() {
        app.speech.stop()
        if let classServices = app.classServices {
            Task { await classServices.syncNow(pupil: pupil) }
        }
        dismiss()
    }
}

struct QuestionCard: View {
    var question: Question
    var objective: Objective?
    var session: PracticeSession
    var pupil: PupilProfile
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(objective?.childTitle ?? question.strand.title, systemImage: question.strand.symbolName)
                    .pupilText(.subheadline, weight: .bold)
                    .foregroundStyle(theme.color(for: question.strand))
                Spacer()
                Button {
                    app.speech.speak(question.audioText, slowly: pupil.yearGroup <= 2 || question.type == .spelling)
                } label: {
                    Label("Read to me", systemImage: "speaker.wave.2.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .frame(width: 48, height: 48)
                        .background(theme.primary.opacity(0.12), in: Circle())
                }
                .accessibilityLabel("Read the question to me")
            }

            HighlightedText(text: question.prompt, highlight: question.highlight)
                .pupilText(.title2, weight: .semibold)
                .fixedSize(horizontal: false, vertical: true)

            if session.mode.givesInstantFeedback, let rule = objective?.rule {
                if session.hintShown {
                    Label(rule, systemImage: "lightbulb.fill")
                        .pupilText(.callout)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.star.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                } else if session.phase == .answering {
                    Button {
                        session.hintShown = true
                    } label: {
                        Label("I need a hint", systemImage: "lightbulb")
                    }
                    .pupilText(.callout, weight: .semibold)
                    .foregroundStyle(theme.primary)
                }
            }
        }
        .card()
    }
}
