import Foundation

/// A *styling* choice, not a claim to reproduce the private macOS 26 renderer.
/// Crystal leaves desktop pixels optically unchanged: no screenshot, no blur,
/// no refraction. App-owned Metal textures can be refracted separately.
public enum GlassOpticalStyle: Int, CaseIterable {
    case crystal = 0
    case balanced = 1
    case frosted = 2

    public var title: String {
        switch self {
        case .crystal: return "Crystal"
        case .balanced: return "Balanced"
        case .frosted: return "Frosted"
        }
    }
}

/// Pure data so the optics can be regression-tested without AppKit or a Mac.
public struct GlassOpticsProfile {
    public let nativeBlurOpacity: Double
    public let neutralOverlayOpacity: Double
    public let upperRimOpacity: Double
    public let innerRimOpacity: Double
    public let edgeBandOpacity: Double
    public let shadowOpacity: Double

    public init(style: GlassOpticalStyle) {
        switch style {
        case .crystal:
            nativeBlurOpacity = 0
            neutralOverlayOpacity = 0.014
            upperRimOpacity = 0.92
            innerRimOpacity = 0.47
            edgeBandOpacity = 0.75
            shadowOpacity = 0.17
        case .balanced:
            nativeBlurOpacity = 0.28
            neutralOverlayOpacity = 0.018
            upperRimOpacity = 0.82
            innerRimOpacity = 0.43
            edgeBandOpacity = 0.68
            shadowOpacity = 0.17
        case .frosted:
            nativeBlurOpacity = 0.83
            neutralOverlayOpacity = 0.018
            upperRimOpacity = 0.68
            innerRimOpacity = 0.34
            edgeBandOpacity = 0.56
            shadowOpacity = 0.13
        }
    }
}
