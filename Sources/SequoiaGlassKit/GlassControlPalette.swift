import Foundation

/// Fixed light-control palette for content over unpredictable wallpapers.
/// The optical glass behind the controls remains genuinely transparent.
public struct GlassRGB: Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(_ red: Double, _ green: Double, _ blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    private static func linear(_ sRGB: Double) -> Double {
        let v = min(1, max(0, sRGB))
        return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }

    public var relativeLuminance: Double {
        0.2126 * Self.linear(red)
        + 0.7152 * Self.linear(green)
        + 0.0722 * Self.linear(blue)
    }

    public func contrastRatio(against other: GlassRGB) -> Double {
        let light = max(relativeLuminance, other.relativeLuminance)
        let dark = min(relativeLuminance, other.relativeLuminance)
        return (light + 0.05) / (dark + 0.05)
    }
}

public enum GlassControlPalette {
    public static let fieldBackground = GlassRGB(0.985, 0.990, 1.0)
    public static let fieldText = GlassRGB(0.12, 0.15, 0.19)
    public static let fieldPlaceholder = GlassRGB(0.33, 0.36, 0.40)
}
