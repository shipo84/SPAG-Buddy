import Foundation
import SwiftUI

struct AnswerInputView: View {
    var question: Question
    @Binding var answer: PupilAnswer?
    var locked: Bool

    var body: some View {
        Group {
            switch question.type {
            case .multipleChoice:
                ChoiceListInput(question: question, multiple: false, answer: $answer, locked: locked)
            case .multiSelect:
                ChoiceListInput(question: question, multiple: true, answer: $answer, locked: locked)
            case .spelling:
                TypedAnswerInput(question: question, answer: $answer, locked: locked, placeholder: "Type the word", multiline: false)
            case .rewrite:
                TypedAnswerInput(question: question, answer: $answer, locked: locked, placeholder: "Write your answer here", multiline: true)
            case .tapGap:
                TapGapInput(question: question, answer: $answer, locked: locked)
            }
        }
        .disabled(locked)
    }
}

private struct ChoiceListInput: View {
    var question: Question
    var multiple: Bool
    @Binding var answer: PupilAnswer?
    var locked: Bool
    @Environment(\.appTheme) private var theme

    private var selected: Set<String> {
        switch answer {
        case .choice(let choice): [choice]
        case .choices(let choices): choices
        default: []
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if multiple {
                Text("Tick all the right answers.")
                    .pupilText(.subheadline, weight: .semibold)
                    .foregroundStyle(theme.secondaryText)
            }
            ForEach(question.choices, id: \.self) { choice in
                Button {
                    toggle(choice)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: symbol(for: choice))
                            .font(.title2)
                            .foregroundStyle(color(for: choice))
                        Text(choice)
                            .pupilText(.title3, weight: .semibold)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                    .background(background(for: choice), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selected.contains(choice) ? color(for: choice) : theme.cardBorder,
                                    lineWidth: selected.contains(choice) ? 3 : theme.borderWidth)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected.contains(choice) ? .isSelected : [])
                .accessibilityValue(accessibilityValue(for: choice))
            }
        }
    }

    private func toggle(_ choice: String) {
        if multiple {
            var set = selected
            if set.contains(choice) { set.remove(choice) } else { set.insert(choice) }
            answer = .choices(set)
        } else {
            answer = .choice(choice)
        }
    }

    private var isCorrectAnswer: (String) -> Bool { { question.answers.contains($0) } }

    private func symbol(for choice: String) -> String {
        if locked && isCorrectAnswer(choice) { return "checkmark.circle.fill" }
        if locked && selected.contains(choice) { return "xmark.circle.fill" }
        if multiple { return selected.contains(choice) ? "checkmark.square.fill" : "square" }
        return selected.contains(choice) ? "largecircle.fill.circle" : "circle"
    }

    private func color(for choice: String) -> Color {
        if locked && isCorrectAnswer(choice) { return theme.correct }
        if locked && selected.contains(choice) { return theme.tryAgain }
        return selected.contains(choice) ? theme.primary : theme.secondaryText
    }

    private func background(for choice: String) -> Color {
        if locked && isCorrectAnswer(choice) { return theme.correct.opacity(0.12) }
        return selected.contains(choice) ? theme.primary.opacity(0.08) : theme.card
    }

    private func accessibilityValue(for choice: String) -> String {
        guard locked else { return "" }
        if isCorrectAnswer(choice) { return "Correct answer" }
        return selected.contains(choice) ? "Your answer" : ""
    }
}

/// Free typing with autocorrect, predictive text and auto-capitals switched off so the keyboard cannot give answers away.
private struct TypedAnswerInput: View {
    var question: Question
    @Binding var answer: PupilAnswer?
    var locked: Bool
    var placeholder: String
    var multiline: Bool

    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 14) {
            if question.type == .spelling {
                Button {
                    app.speech.speak(question.audioText, slowly: true)
                } label: {
                    Label("Hear the word again", systemImage: "ear.fill")
                }
                .buttonStyle(.big(theme.color(for: .spelling)))
            }

            TextField(placeholder, text: $text, axis: multiline ? .vertical : .horizontal)
                .lineLimit(multiline ? 2...5 : 1...1)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.done)
                .focused($focused)
                .pupilText(question.type == .spelling ? .largeTitle : .title3, weight: .semibold)
                .multilineTextAlignment(question.type == .spelling ? .center : .leading)
                .padding(16)
                .background(theme.card, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(focused ? theme.primary : theme.cardBorder, lineWidth: focused ? 3 : theme.borderWidth))
                .onChange(of: text) { _, newValue in answer = .text(newValue) }
        }
        .onAppear { focused = question.type == .spelling }
        .onChange(of: question.id) { _, _ in text = "" }
    }
}

/// Tap between words to place a punctuation mark, as in SATs "insert the missing comma" questions.
private struct TapGapInput: View {
    var question: Question
    @Binding var answer: PupilAnswer?
    var locked: Bool
    @Environment(\.appTheme) private var theme

    private var chosen: Set<Int> {
        if case .gaps(let gaps) = answer { return gaps }
        return []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tap between the words to add a \(markName).")
                .pupilText(.subheadline, weight: .semibold)
                .foregroundStyle(theme.secondaryText)

            FlowLayout(spacing: 2, lineSpacing: 14) {
                ForEach(Array(question.tokens.enumerated()), id: \.offset) { index, token in
                    Text(token)
                        .pupilText(.title2, weight: .semibold)
                        .accessibilityHidden(true)
                    if index < question.tokens.count - 1 {
                        gapButton(after: index, word: token)
                    }
                }
            }
            .card(padding: 18)
        }
    }

    private var markName: String {
        switch question.mark {
        case ",": "comma"
        case "'": "apostrophe"
        case ";": "semi-colon"
        case ":": "colon"
        case "-": "hyphen"
        case "!": "exclamation mark"
        case "?": "question mark"
        case ".": "full stop"
        default: "punctuation mark"
        }
    }

    private func gapButton(after index: Int, word: String) -> some View {
        let isChosen = chosen.contains(index)
        let isAnswer = question.gapAnswers.contains(index)
        let color: Color = locked ? (isAnswer ? theme.correct : (isChosen ? theme.tryAgain : theme.secondaryText)) : theme.primary

        return Button {
            var gaps = chosen
            if gaps.contains(index) { gaps.remove(index) } else { gaps.insert(index) }
            answer = .gaps(gaps)
        } label: {
            ZStack {
                if isChosen || (locked && isAnswer) {
                    Text(question.mark ?? "")
                        .font(.system(.title, design: .rounded).weight(.black))
                        .foregroundStyle(color)
                } else {
                    Capsule()
                        .fill(theme.primary.opacity(0.25))
                        .frame(width: 4, height: 24)
                }
            }
            .frame(width: 28, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Gap after \(word)")
        .accessibilityValue(isChosen ? "\(markName) added" : "empty")
    }
}
