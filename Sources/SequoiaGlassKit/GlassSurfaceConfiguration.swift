import AppKit

/// One set of visual options shared by AppKit and SwiftUI integrations.
///
/// The defaults match the existing Crystal renderer. This value only
/// configures app-owned surfaces; it does not change system windows.
public struct GlassSurfaceConfiguration {
    public var cornerRadius: CGFloat
    public var opticalStyle: GlassOpticalStyle
    public var appearanceMode: GlassSurfaceAppearance
    public var material: NSVisualEffectView.Material
    public var highlights: Bool

    public init(cornerRadius: CGFloat = 24,
                opticalStyle: GlassOpticalStyle = .crystal,
                appearanceMode: GlassSurfaceAppearance = .system,
                material: NSVisualEffectView.Material = .popover,
                highlights: Bool = true) {
        self.cornerRadius = cornerRadius
        self.opticalStyle = opticalStyle
        self.appearanceMode = appearanceMode
        self.material = material
        self.highlights = highlights
    }

    /// Reconfigure an existing surface without replacing its content views.
    @MainActor
    public func apply(to view: SystemGlassSurfaceView) {
        view.cornerRadius = cornerRadius
        view.opticalStyle = opticalStyle
        view.appearanceMode = appearanceMode
        view.appearanceMaterial = material
        view.showHighlights = highlights
    }
}

@MainActor
public extension SystemGlassSurfaceView {
    /// AppKit convenience initializer; retain the original `init(frame:)` API.
    convenience init(frame: NSRect = .zero,
                     configuration: GlassSurfaceConfiguration) {
        self.init(frame: frame)
        configuration.apply(to: self)
    }

    /// Change style or theme while preserving the surface and its controls.
    func configure(with configuration: GlassSurfaceConfiguration) {
        configuration.apply(to: self)
    }
}
