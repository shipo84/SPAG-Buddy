import Foundation
import SwiftUI

/// Per-pupil look and feel, driven by the edition, light or dark mode and the pupil's accessibility settings.
/// High contrast is always black on white, so it ignores dark mode.
public struct AppTheme {
    public var easyRead = false
    public var highContrast = false
    public var edition = Edition.home
    public var colorScheme = ColorScheme.light

    private var palette: EditionPalette { edition.palette }
    private var isDark: Bool { colorScheme == .dark && !highContrast }

    public var background: Color {
        if highContrast { return .white }
        return (isDark ? EditionPalette.darkBackground : palette.tintBackground).color
    }
    public var card: Color { isDark ? EditionPalette.darkCard.color : .white }
    public var cardBorder: Color {
        if highContrast { return .black }
        return isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }
    public var text: Color {
        if highContrast { return .black }
        return (isDark ? palette.tintBackground : EditionPalette.ink).color
    }
    public var secondaryText: Color {
        if highContrast { return .black }
        return (isDark ? EditionPalette.darkSecondaryText : EditionPalette.slate).color
    }
    /// Brand colour for icons, rings, dots and progress bars. Not for text: see `primaryText`.
    public var primary: Color {
        if highContrast { return palette.primaryHighContrast.color }
        return (isDark ? palette.primaryLight : palette.primary).color
    }
    /// Brand colour for text, links and toolbar buttons. Meets 4.5:1 on `background` and `card`.
    public var primaryText: Color {
        if highContrast { return palette.primaryHighContrast.color }
        return (isDark ? palette.primaryLight : palette.primaryStrong).color
    }
    /// Fill behind `onPrimary` text. Meets 4.5:1 with white in both modes.
    public var primaryFill: Color {
        (highContrast ? palette.primaryHighContrast : palette.primaryStrong).color
    }
    public var onPrimary: Color { .white }
    /// Fill for secondary big buttons, such as "Someone new". Meets 4.5:1 with white in both modes.
    public var neutralFill: Color { highContrast ? .black : EditionPalette.slate.color }
    public var buddy: Color { highContrast ? primaryFill : EditionPalette.owlOrange.color }
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

    public init(easyRead: Bool = false, highContrast: Bool = false, edition: Edition = .home, colorScheme: ColorScheme = .light) {
        self.easyRead = easyRead
        self.highContrast = highContrast
        self.edition = edition
        self.colorScheme = colorScheme
    }

    init(pupil: PupilProfile?, edition: Edition, colorScheme: ColorScheme) {
        easyRead = pupil?.easyReadText ?? false
        highContrast = pupil?.highContrast ?? false
        self.edition = edition
        self.colorScheme = colorScheme
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
            .background((color ?? theme.primaryFill).opacity(isEnabled ? 1 : 0.4), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BigButtonStyle {
    public static var big: BigButtonStyle { BigButtonStyle() }
    public static func big(_ color: Color) -> BigButtonStyle { BigButtonStyle(color: color) }
}
