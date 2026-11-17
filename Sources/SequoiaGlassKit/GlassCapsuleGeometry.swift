import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Layout for the same rounded-rectangle lens shape used by the Metal shader.
/// All rectangles are in VIEW POINTS, top-left origin, not device pixels.
/// No private macOS APIs are required.
public enum GlassCapsuleGeometry {
    /// Matches SynchronizedGlassView's default one-lens geometry.
    /// Insets are derived from the viewport, then limited to avoid oversized controls.
    public static func centered(in size: CGSize, scale: CGFloat = 0.75) -> CGRect {
        let w = max(0, size.width)
        let h = max(0, size.height)
        let s = max(CGFloat(0.55), min(CGFloat(1.4), scale))
        let hw = min(w * 0.34, 335) * s
        let hh = min(h * 0.24, 146) * s
        return CGRect(x: w * 0.50 - hw, y: h * 0.52 - hh,
                      width: 2 * hw, height: 2 * hh)
    }

    /// Keeps a requested lens fully inside an app's render surface.
    public static func contained(_ requested: CGRect, in size: CGSize) -> CGRect {
        let w = max(0, size.width), h = max(0, size.height)
        let rw = max(0, min(requested.size.width, w))
        let rh = max(0, min(requested.size.height, h))
        let x = min(max(0, requested.origin.x), max(0, w - rw))
        let y = min(max(0, requested.origin.y), max(0, h - rh))
        return CGRect(x: x, y: y, width: rw, height: rh)
    }
}
