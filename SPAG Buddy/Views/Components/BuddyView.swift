import Foundation
import SwiftUI

/// The SPAG Buddy character. It only ever says fixed, encouraging lines. It never chats.
struct BuddyView: View {
    enum Mood {
        case happy
        case thinking
        case cheering
        case encouraging
    }

    var mood: Mood = .happy
    var size: CGFloat = 96

    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounce = false

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.highContrast ? theme.primary : Color(red: 0.55, green: 0.5, blue: 0.98))
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: size * 0.45)
                .offset(x: -size * 0.18, y: -size * 0.2)

            HStack(spacing: size * 0.18) {
                eye
                eye
            }
            .offset(y: -size * 0.06)

            mouth
                .stroke(.white, style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round))
                .frame(width: size * 0.34, height: size * 0.16)
                .offset(y: size * 0.18)

            if mood == .cheering {
                ForEach(0..<3) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: size * 0.2))
                        .foregroundStyle(theme.star)
                        .offset(x: [-0.55, 0.55, 0.4][index] * size, y: [-0.35, -0.4, 0.4][index] * size)
                }
            }
        }
        .frame(width: size, height: size)
        .offset(y: bounce ? -4 : 0)
        .onAppear {
            guard !reduceMotion, mood == .cheering || mood == .happy else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { bounce = true }
        }
        .accessibilityHidden(true)
    }

    private var eye: some View {
        Capsule()
            .fill(.white)
            .frame(width: size * 0.1, height: mood == .thinking ? size * 0.06 : size * 0.16)
    }

    private var mouth: Path {
        Path { path in
            let width = size * 0.34
            let height = size * 0.16
            switch mood {
            case .thinking:
                path.move(to: CGPoint(x: width * 0.2, y: height * 0.5))
                path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.5))
            case .happy, .cheering, .encouraging:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addQuadCurve(to: CGPoint(x: width, y: 0), control: CGPoint(x: width / 2, y: height * (mood == .encouraging ? 1.2 : 2)))
            }
        }
    }
}

/// Buddy with a speech bubble.
struct BuddySays: View {
    var text: String
    var mood: BuddyView.Mood = .happy
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            BuddyView(mood: mood, size: 64)
            Text(text)
                .pupilText(.headline, weight: .semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(theme.cardBorder, lineWidth: theme.borderWidth))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 24) {
        HStack {
            BuddyView(mood: .happy)
            BuddyView(mood: .thinking)
            BuddyView(mood: .cheering)
        }
        BuddySays(text: "Ready for some practice?")
    }
    .padding()
}
