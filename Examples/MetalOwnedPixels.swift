// Integration sketch for apps that already render their OWN Metal scene.
// This is NOT a standalone renderer: drawOwnedPixels must encode valid
// host-owned draw calls using a pipeline compatible with the source texture.
import AppKit
import Metal
import SequoiaGlassMetal

@MainActor
func makeOwnedContentGlass(
    frame: CGRect,
    drawOwnedPixels: @escaping (MTLRenderCommandEncoder, CGSize, Double) -> Void
) -> SynchronizedGlassView {
    let view = SynchronizedGlassView(frame: frame, device: nil)
    view.playbackPaused = true             // event-driven; no permanent loop
    view.encodeContent = { encoder, size, time in
        drawOwnedPixels(encoder, size, time)
        // Important: do NOT call encoder.endEncoding() here.
    }
    // Call view.requestContentFrame() when the host scene changes.
    return view
}
