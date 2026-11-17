import AppKit
import XCTest
import SequoiaGlassKit

final class PublicAPITests: XCTestCase {
    func testDefaultConfigurationPreservesCrystal() {
        let config = GlassSurfaceConfiguration()
        XCTAssertEqual(config.opticalStyle, .crystal)
        XCTAssertEqual(config.appearanceMode, .system)
        XCTAssertEqual(config.cornerRadius, 24)
        XCTAssertEqual(config.material, .popover)
        XCTAssertTrue(config.highlights)
    }

    func testCustomConfigurationRetainsValues() {
        let config = GlassSurfaceConfiguration(cornerRadius: 32,
                                                opticalStyle: .balanced,
                                                appearanceMode: .dark,
                                                material: .menu,
                                                highlights: false)
        XCTAssertEqual(config.cornerRadius, 32)
        XCTAssertEqual(config.opticalStyle, .balanced)
        XCTAssertEqual(config.appearanceMode, .dark)
        XCTAssertEqual(config.material, .menu)
        XCTAssertFalse(config.highlights)
    }

    func testApprovedCrystalOpticsConstants() {
        let optics = GlassOpticsProfile(style: .crystal)
        XCTAssertEqual(optics.nativeBlurOpacity, 0)
        XCTAssertEqual(optics.neutralOverlayOpacity, 0.014)
        XCTAssertEqual(optics.upperRimOpacity, 0.92)
        XCTAssertEqual(optics.innerRimOpacity, 0.47)
        XCTAssertEqual(optics.edgeBandOpacity, 0.75)
        XCTAssertEqual(optics.shadowOpacity, 0.17)
    }

    func testStylesAreUniqueAndStable() {
        XCTAssertEqual(GlassOpticalStyle.allCases.count, 3)
        XCTAssertEqual(GlassOpticalStyle.allCases.map(\.rawValue), [0, 1, 2])
        XCTAssertEqual(GlassOpticalStyle.allCases.map(\.title), ["Crystal", "Balanced", "Frosted"])
    }

    func testSearchPaletteContrast() {
        XCTAssertGreaterThanOrEqual(
            GlassControlPalette.fieldText.contrastRatio(
                against: GlassControlPalette.fieldBackground), 7.0)
        XCTAssertGreaterThanOrEqual(
            GlassControlPalette.fieldPlaceholder.contrastRatio(
                against: GlassControlPalette.fieldBackground), 4.5)
    }
}
