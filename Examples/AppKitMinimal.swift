// Illustrative AppKit snippet for an existing application's main-actor UI.
// Not a standalone program. Configure an app-owned, nonopaque NSWindow.
import AppKit
import SequoiaGlassKit

@MainActor
func installGlass(in parentView: NSView, existingButton: NSButton) {
    let options = GlassSurfaceConfiguration(cornerRadius: 28,
                                            opticalStyle: .crystal)
    let glass = SystemGlassSurfaceView(
        frame: NSRect(x: 24, y: 24, width: 340, height: 84),
        configuration: options)
    parentView.addSubview(glass)

    // The SDK does not replace or intercept the app's existing control action.
    existingButton.frame = NSRect(x: 20, y: 25, width: 120, height: 32)
    glass.contentView.addSubview(existingButton)
}

// Call on the host's existing window when appropriate:
// window.isOpaque = false
// window.backgroundColor = .clear
