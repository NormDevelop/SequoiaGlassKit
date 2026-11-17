import SequoiaGlassKit
#if canImport(SwiftUI)
import AppKit
import Metal
import SwiftUI

/// SwiftUI bridge with real AppKit controls above an app-owned Metal scene.
/// If using ordinary SwiftUI views for background content, use the snapshot
/// compatibility path rather than assuming they can be sampled by this shader.
@available(macOS 13.0, *)
public struct GlassControlsSurface: NSViewRepresentable {
    public var title: String
    public var subtitle: String
    public var primaryButtonTitle: String
    public var secondaryButtonTitle: String
    public var refractionPoints: Float
    public var onPrimaryAction: (() -> Void)?
    public var onSecondaryAction: (() -> Void)?
    public var encodeContent: ((MTLRenderCommandEncoder, CGSize, Double) -> Void)?

    public init(title: String = "Glass control", subtitle: String = "Same-frame Metal",
                primaryButtonTitle: String = "Play", secondaryButtonTitle: String = "Next",
                refractionPoints: Float = 7,
                onPrimaryAction: (() -> Void)? = nil,
                onSecondaryAction: (() -> Void)? = nil,
                encodeContent: ((MTLRenderCommandEncoder, CGSize, Double) -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.refractionPoints = refractionPoints
        self.onPrimaryAction = onPrimaryAction
        self.onSecondaryAction = onSecondaryAction
        self.encodeContent = encodeContent
    }

    public func makeNSView(context: Context) -> GlassControlsView {
        let view = GlassControlsView(frame: .zero)
        configure(view)
        return view
    }

    public func updateNSView(_ view: GlassControlsView, context: Context) {
        configure(view)
    }

    private func configure(_ view: GlassControlsView) {
        view.title = title
        view.subtitle = subtitle
        view.primaryButtonTitle = primaryButtonTitle
        view.secondaryButtonTitle = secondaryButtonTitle
        view.renderer.refractionPoints = refractionPoints
        view.renderer.encodeContent = encodeContent
        view.onPrimaryAction = onPrimaryAction
        view.onSecondaryAction = onSecondaryAction
    }
}
#endif
