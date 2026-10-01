import Foundation
import SwiftUI

/// An sRGB colour written as 0xRRGGBB. Kept as a number so tests can check WCAG contrast.
public struct ColorToken: Hashable, Sendable {
    public let hex: UInt32

    public init(_ hex: UInt32) {
        self.hex = hex
    }

    public static let white = ColorToken(0xFFFFFF)
    public static let black = ColorToken(0x000000)

    private var components: (red: Double, green: Double, blue: Double) {
        (Double((hex >> 16) & 0xFF) / 255, Double((hex >> 8) & 0xFF) / 255, Double(hex & 0xFF) / 255)
    }

    public var color: Color {
        Color(.sRGB, red: components.red, green: components.green, blue: components.blue)
    }

    /// WCAG 2.x relative luminance.
    public var relativeLuminance: Double {
        func linear(_ value: Double) -> Double {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let (red, green, blue) = components
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// WCAG 2.x contrast ratio, from 1 to 21. AA needs 4.5 for body text.
    public func contrastRatio(with other: ColorToken) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

/// Brand colours for one edition. Views read them through `AppTheme`, never directly.
public struct EditionPalette: Sendable {
    public let primary: ColorToken
    public let primaryLight: ColorToken
    public let tintBackground: ColorToken
    /// `primary` darkened until white text on it, and it as text on `tintBackground`, reach 4.5:1.
    /// White on `primary` itself is only about 3.5:1, so buttons and text links use this.
    public let primaryStrong: ColorToken
    /// For the pupil's high-contrast setting: white text on it reaches 7:1.
    public let primaryHighContrast: ColorToken

    public static let home = EditionPalette(
        primary: ColorToken(0xE4528C),
        primaryLight: ColorToken(0xFF9EC4),
        tintBackground: ColorToken(0xFFF0F6),
        primaryStrong: ColorToken(0xCC2064),
        primaryHighContrast: ColorToken(0xAA1B54)
    )

    public static let school = EditionPalette(
        primary: ColorToken(0x3D8CE0),
        primaryLight: ColorToken(0x5AA6F5),
        tintBackground: ColorToken(0xE8F4FD),
        primaryStrong: ColorToken(0x1E6BBD),
        primaryHighContrast: ColorToken(0x19599E)
    )

    // Shared by both editions.
    public static let owlOrange = ColorToken(0xF2A94E)
    public static let success = ColorToken(0x34C759)
    public static let warning = ColorToken(0xFFB347)
    public static let error = ColorToken(0xFF6B8A)
    public static let ink = ColorToken(0x24364A)

    /// Ink-family grey for secondary text in light mode, and the fill for neutral buttons in both modes.
    public static let slate = ColorToken(0x56677A)
    public static let darkBackground = ColorToken(0x141C26)
    /// Cards in dark mode are ink, so ink stays the one dark neutral.
    public static let darkCard = ink
    public static let darkSecondaryText = ColorToken(0xB3BFCC)
}

extension Edition {
    public var palette: EditionPalette {
        switch self {
        case .home: .home
        case .school: .school
        }
    }

    /// The app's name as shown inside the app.
    public var displayName: String {
        switch self {
        case .home: "SPAG Buddy Home"
        case .school: "SPAG Buddy School"
        }
    }
}
