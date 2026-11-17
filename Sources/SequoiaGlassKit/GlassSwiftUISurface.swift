#if canImport(SwiftUI)
import AppKit
import SwiftUI

/// Native Sequoia behind-window material for SwiftUI controls.
/// No screen capture or private API. Use as a BACKGROUND, not a replacement
/// for app-owned content or for the macOS system menu bar.
@available(macOS 13.0, *)
public struct SequoiaGlassSurface: NSViewRepresentable {
    public var cornerRadius: CGFloat
    public var opticalStyle: GlassOpticalStyle
    public var appearanceMode: GlassSurfaceAppearance
    public var material: NSVisualEffectView.Material
    public var highlights: Bool

    public init(cornerRadius: CGFloat = 24,
                opticalStyle: GlassOpticalStyle = .crystal,
                appearanceMode: GlassSurfaceAppearance = .system,
                material: NSVisualEffectView.Material = .menu,
                highlights: Bool = true) {
        self.cornerRadius = cornerRadius
        self.opticalStyle = opticalStyle
        self.appearanceMode = appearanceMode
        self.material = material
        self.highlights = highlights
    }

    /// Use the same configuration model as the AppKit convenience initializer.
    public init(configuration: GlassSurfaceConfiguration) {
        self.init(cornerRadius: configuration.cornerRadius,
                  opticalStyle: configuration.opticalStyle,
                  appearanceMode: configuration.appearanceMode,
                  material: configuration.material,
                  highlights: configuration.highlights)
    }

    public func makeNSView(context: Context) -> SystemGlassSurfaceView {
        let view = SystemGlassSurfaceView(frame: .zero)
        view.cornerRadius = cornerRadius
        view.opticalStyle = opticalStyle
        view.appearanceMode = appearanceMode
        view.appearanceMaterial = material
        view.showHighlights = highlights
        return view
    }

    public func updateNSView(_ view: SystemGlassSurfaceView, context: Context) {
        view.cornerRadius = cornerRadius
        view.opticalStyle = opticalStyle
        view.appearanceMode = appearanceMode
        view.appearanceMaterial = material
        view.showHighlights = highlights
    }
}

/// Ready-to-use SwiftUI container. Existing app controls remain ordinary
/// SwiftUI views; the material is drawn only in the background.
@available(macOS 13.0, *)
public struct SequoiaGlassPanel<Content: View>: View {
    public let configuration: GlassSurfaceConfiguration
    public let contentPadding: CGFloat
    private let panelContent: Content

    public init(configuration: GlassSurfaceConfiguration = GlassSurfaceConfiguration(),
                contentPadding: CGFloat = 16,
                @ViewBuilder content: () -> Content) {
        self.configuration = configuration
        self.contentPadding = contentPadding
        self.panelContent = content()
    }

    public var body: some View {
        panelContent
            .padding(contentPadding)
            .sequoiaGlass(configuration: configuration)
    }
}

@available(macOS 13.0, *)
public extension View {
    /// Shared options for SwiftUI and AppKit (preferred for new integrations).
    func sequoiaGlass(configuration: GlassSurfaceConfiguration) -> some View {
        self.background(SequoiaGlassSurface(configuration: configuration))
    }

    /// Convenience background for interactive SwiftUI controls. Native blur;
    /// if you additionally want refracted GPU content, supply a Metal source
    /// to the separately documented OpticalRefractionView.
    func sequoiaGlass(cornerRadius: CGFloat = 24,
                      opticalStyle: GlassOpticalStyle = .crystal,
                      appearanceMode: GlassSurfaceAppearance = .system,
                      material: NSVisualEffectView.Material = .menu,
                      highlights: Bool = true) -> some View {
        self.background(
            SequoiaGlassSurface(cornerRadius: cornerRadius,
                                 opticalStyle: opticalStyle,
                                 appearanceMode: appearanceMode,
                                 material: material,
                                 highlights: highlights))
    }
}
#endif
