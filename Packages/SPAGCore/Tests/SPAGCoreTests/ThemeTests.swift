import Foundation
import Testing
@testable import SPAGCore

@MainActor
struct ThemeTests {
    @Test func palettesMatchTheBrandSpec() {
        #expect(EditionPalette.home.primary.hex == 0xE4528C)
        #expect(EditionPalette.home.primaryLight.hex == 0xFF9EC4)
        #expect(EditionPalette.home.tintBackground.hex == 0xFFF0F6)
        #expect(EditionPalette.school.primary.hex == 0x3D8CE0)
        #expect(EditionPalette.school.primaryLight.hex == 0x5AA6F5)
        #expect(EditionPalette.school.tintBackground.hex == 0xE8F4FD)
        #expect(EditionPalette.owlOrange.hex == 0xF2A94E)
        #expect(EditionPalette.success.hex == 0x34C759)
        #expect(EditionPalette.warning.hex == 0xFFB347)
        #expect(EditionPalette.error.hex == 0xFF6B8A)
        #expect(EditionPalette.ink.hex == 0x24364A)
    }

    @Test func contrastRatioMatchesWCAG() {
        #expect(abs(ColorToken.black.contrastRatio(with: .white) - 21) < 0.01)
        #expect(abs(ColorToken.white.contrastRatio(with: .white) - 1) < 0.01)
    }

    /// Why buttons use `primaryStrong`: neither white nor ink reaches AA on the brand primaries.
    @Test func brandPrimariesAreTooLightForButtonText() {
        for palette in [EditionPalette.home, .school] {
            #expect(palette.primary.contrastRatio(with: .white) < 4.5)
            #expect(palette.primary.contrastRatio(with: EditionPalette.ink) < 4.5)
        }
    }

    @Test(arguments: Edition.allCases)
    func lightModeTextMeetsAA(_ edition: Edition) {
        let palette = edition.palette
        #expect(palette.primaryStrong.contrastRatio(with: .white) >= 4.5)
        #expect(palette.primaryStrong.contrastRatio(with: palette.tintBackground) >= 4.5)
        #expect(EditionPalette.ink.contrastRatio(with: palette.tintBackground) >= 4.5)
        #expect(EditionPalette.slate.contrastRatio(with: palette.tintBackground) >= 4.5)
        #expect(EditionPalette.slate.contrastRatio(with: .white) >= 4.5)
    }

    @Test(arguments: Edition.allCases)
    func darkModeTextMeetsAA(_ edition: Edition) {
        let palette = edition.palette
        for surface in [EditionPalette.darkBackground, EditionPalette.darkCard] {
            #expect(palette.tintBackground.contrastRatio(with: surface) >= 4.5)
            #expect(palette.primaryLight.contrastRatio(with: surface) >= 4.5)
            #expect(EditionPalette.darkSecondaryText.contrastRatio(with: surface) >= 4.5)
        }
    }

    @Test(arguments: Edition.allCases)
    func highContrastPrimaryMeetsAAA(_ edition: Edition) {
        #expect(edition.palette.primaryHighContrast.contrastRatio(with: .white) >= 7)
    }

    @Test func eachEditionShowsItsOwnName() {
        #expect(Edition.home.displayName == "SPAG Buddy Home")
        #expect(Edition.school.displayName == "SPAG Buddy School")
    }
}
