import Foundation
import SwiftUI

/// Per-pupil look and feel, driven by the pupil's accessibility settings.
public struct AppTheme {
    public var easyRead = false
    public var highContrast = false

    public var background: Color { highContrast ? .white : Color(red: 0.96, green: 0.96, blue: 1.0) }
    public var card: Color { highContrast ? .white : .white }
    public var cardBorder: Color { highContrast ? .black : Color.black.opacity(0.06) }
    public var text: Color { highContrast ? .black : Color(red: 0.12, green: 0.12, blue: 0.22) }
    public var secondaryText: Color { highContrast ? .black : Color(red: 0.35, green: 0.36, blue: 0.48) }
    public var primary: Color { highContrast ? Color(red: 0.0, green: 0.15, blue: 0.55) : Color(red: 0.33, green: 0.30, blue: 0.85) }
    public var onPrimary: Color { .white }
    public var correct: Color { highContrast ? Color(red: 0.0, green: 0.4, blue: 0.1) : Color(red: 0.13, green: 0.62, blue: 0.36) }
    /// Used for wrong answers. Orange rather than red keeps feedback gentle.
    public var tryAgain: Color { highContrast ? Color(red: 0.6, green: 0.25, blue: 0.0) : Color(red: 0.93, green: 0.52, blue: 0.13) }
    public var star: Color { Color(red: 0.98, green: 0.72, blue: 0.1) }
    public var borderWidth: CGFloat { highContrast ? 2 : 1 }

    func color(for strand: Strand) -> Color {
        if highContrast { return primary }
        switch strand {
        case .spelling: return Color(red: 0.95, green: 0.45, blue: 0.35)
        case .punctuation: return Color(red: 0.2, green: 0.6, blue: 0.85)
        case .grammar: return Color(red: 0.45, green: 0.35, blue: 0.85)
        case .vocabulary: return Color(red: 0.2, green: 0.65, blue: 0.5)
        }
    }

    public init(easyRead: Bool = false, highContrast: Bool = false) {
        self.easyRead = easyRead
        self.highContrast = highContrast
    }

    init(pupil: PupilProfile?) {
        easyRead = pupil?.easyReadText ?? false
        highContrast = pupil?.highContrast ?? false
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme()
}

extension EnvironmentValues {
    public var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

/// Rounded, Dynamic Type friendly text. Easy-read adds letter and line spacing, which many pupils with dyslexia find helpful.
private struct PupilTextModifier: ViewModifier {
    @Environment(\.appTheme) private var theme
    var style: Font.TextStyle
    var weight: Font.Weight

    func body(content: Content) -> some View {
        content
            .font(.system(style, design: .rounded).weight(weight))
            .tracking(theme.easyRead ? 1.2 : 0)
            .lineSpacing(theme.easyRead ? 8 : 2)
    }
}

extension View {
    public func pupilText(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> some View {
        modifier(PupilTextModifier(style: style, weight: weight))
    }

    public func card(padding: CGFloat = 20) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

private struct CardModifier: ViewModifier {
    @Environment(\.appTheme) private var theme
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(theme.cardBorder, lineWidth: theme.borderWidth))
            .shadow(color: .black.opacity(theme.highContrast ? 0 : 0.06), radius: 10, y: 4)
    }
}

/// Large, high-contrast button used for the main action on each screen. At least 60pt tall for small fingers.
public struct BigButtonStyle: ButtonStyle {
    @Environment(\.appTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    var color: Color?

    public init(color: Color? = nil) {
        self.color = color
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundStyle(theme.onPrimary)
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.horizontal, 20)
            .background((color ?? theme.primary).opacity(isEnabled ? 1 : 0.4), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BigButtonStyle {
    public static var big: BigButtonStyle { BigButtonStyle() }
    public static func big(_ color: Color) -> BigButtonStyle { BigButtonStyle(color: color) }
}
