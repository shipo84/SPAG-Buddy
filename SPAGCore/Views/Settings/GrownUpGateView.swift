import Foundation
import SwiftUI

/// A simple adult check before settings that change or delete data, or that open a web page.
struct GrownUpGateView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var unlocked = false
    @State private var puzzle = Puzzle.random()
    @State private var typed = ""
    @State private var wrong = false

    var body: some View {
        if unlocked {
            content()
        } else {
            NavigationStack {
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill").font(.system(size: 44)).foregroundStyle(theme.primary)
                    Text("Grown-ups only").pupilText(.title, weight: .heavy)
                    Text("Type the answer to carry on.").pupilText(.body).foregroundStyle(theme.secondaryText)
                    Text("\(puzzle.left) × \(puzzle.right) = ?")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                    PinPad(pin: $typed, length: String(puzzle.answer).count)
                        .onChange(of: typed) { _, value in check(value) }
                    if wrong {
                        Text("Not quite. Here's a new one.").foregroundStyle(theme.tryAgain)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .screenBackground()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
    }

    private func check(_ value: String) {
        guard value.count == String(puzzle.answer).count else { return }
        if Int(value) == puzzle.answer {
            unlocked = true
        } else {
            wrong = true
            typed = ""
            puzzle = Puzzle.random()
        }
    }

    private struct Puzzle {
        var left: Int
        var right: Int
        var answer: Int { left * right }

        static func random() -> Puzzle {
            Puzzle(left: Int.random(in: 13...19), right: Int.random(in: 6...9))
        }
    }
}
