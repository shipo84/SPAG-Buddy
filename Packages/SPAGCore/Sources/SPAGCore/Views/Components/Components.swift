import Foundation
import SwiftUI

public struct AvatarView: View {
    var avatar: Avatar?
    var size: CGFloat = 64
    var selected = false
    @Environment(\.appTheme) private var theme

    public init(avatar: Avatar?, size: CGFloat = 64, selected: Bool = false) {
        self.avatar = avatar
        self.size = size
        self.selected = selected
    }

    public var body: some View {
        Text(avatar?.emoji ?? "🙂")
            .font(.system(size: size * 0.6))
            .frame(width: size, height: size)
            .background(Circle().fill(selected ? theme.primary.opacity(0.18) : Color.black.opacity(0.04)))
            .overlay(Circle().stroke(selected ? theme.primary : .clear, lineWidth: 3))
            .accessibilityLabel(avatar?.name ?? "Picture")
    }
}

public struct AvatarGrid: View {
    var avatars: [Avatar]
    @Binding var selection: String?
    var size: CGFloat = 72

    public init(avatars: [Avatar], selection: Binding<String?>, size: CGFloat = 72) {
        self.avatars = avatars
        _selection = selection
        self.size = size
    }

    public var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: size + 12), spacing: 12)], spacing: 12) {
            ForEach(avatars) { avatar in
                Button {
                    selection = avatar.key
                } label: {
                    AvatarView(avatar: avatar, size: size, selected: selection == avatar.key)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(avatar.name)
                .accessibilityAddTraits(selection == avatar.key ? .isSelected : [])
            }
        }
    }
}

/// Large number keypad for PINs. Easier for young children than the system keyboard.
public struct PinPad: View {
    @Binding var pin: String
    var length = 4
    @Environment(\.appTheme) private var theme

    public init(pin: Binding<String>, length: Int = 4) {
        _pin = pin
        self.length = length
    }

    public var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ForEach(0..<length, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? theme.primary : Color.black.opacity(0.1))
                        .frame(width: 22, height: 22)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("\(pin.count) of \(length) numbers entered")

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(84), spacing: 14), count: 3), spacing: 14) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9"], id: \.self) { digit in
                    key(digit)
                }
                Color.clear.frame(height: 72)
                key("0")
                Button {
                    if !pin.isEmpty { pin.removeLast() }
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.title2)
                        .frame(width: 84, height: 72)
                }
                .foregroundStyle(theme.secondaryText)
                .accessibilityLabel("Delete")
            }
        }
    }

    private func key(_ digit: String) -> some View {
        Button {
            if pin.count < length { pin.append(digit) }
        } label: {
            Text(digit)
                .font(.system(.title, design: .rounded).weight(.bold))
                .frame(width: 84, height: 72)
                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .foregroundStyle(theme.text)
    }
}

/// Wraps children onto new lines, like words in a sentence.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let extra = rows[rows.count - 1].indices.isEmpty ? size.width : size.width + spacing
            if rows[rows.count - 1].width + extra > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let isFirst = rows[rows.count - 1].indices.isEmpty
            rows[rows.count - 1].indices.append(index)
            rows[rows.count - 1].width += isFirst ? size.width : size.width + spacing
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }
        return rows.filter { !$0.indices.isEmpty }
    }
}

/// Shows a prompt with the `highlight` phrase underlined and bold, as in SATs papers.
struct HighlightedText: View {
    var text: String
    var highlight: String?

    var body: some View {
        Text(attributed)
    }

    private var attributed: AttributedString {
        var result = AttributedString(text)
        if let highlight, let range = result.range(of: highlight) {
            result[range].underlineStyle = .single
            result[range].inlinePresentationIntent = .stronglyEmphasized
        }
        return result
    }
}

struct StatPill: View {
    var systemImage: String
    var value: String
    var label: String
    var color: Color
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage).foregroundStyle(color)
            Text(value).pupilText(.headline, weight: .bold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.card, in: Capsule())
        .overlay(Capsule().stroke(theme.cardBorder, lineWidth: theme.borderWidth))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}

struct ScreenBackground: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .foregroundStyle(theme.text)
            .background(theme.background.ignoresSafeArea())
            .tint(theme.primary)
    }
}

extension View {
    public func screenBackground() -> some View { modifier(ScreenBackground()) }
}
