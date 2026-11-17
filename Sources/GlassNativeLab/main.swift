import AppKit
import SequoiaGlassKit

/// Minimal demo only. App-owned glass controls on an actual desktop.
/// No system UI modifications, ScreenCaptureKit, or capture permissions.
@MainActor
private final class GlassDemoApp: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let frame = NSRect(x: 0, y: 0, width: 720, height: 250)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        window.title = "SequoiaGlassKit · Crystal Developer Preview"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.hasShadow = false
        window.contentView = DemoContentView(frame: frame)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication) -> Bool { true }
}

@MainActor
private final class DemoContentView: NSView {
    override var isFlipped: Bool { true }

    private let glass = SystemGlassSurfaceView(frame: .zero)
    private let titlePlate = NSView(frame: .zero)
    private let title = NSTextField(labelWithString: "CRYSTAL / SEQUOIA")
    private let detail = NSTextField(labelWithString: "Native, leicht, ohne Bildschirmaufnahme")
    private let searchWell = NSView(frame: .zero)
    private let search = NSSearchField(frame: .zero)
    private let style = NSPopUpButton(frame: .zero, pullsDown: false)
    private let reflection = NSButton(title: "Reflexe: An", target: nil, action: nil)
    private let finder = NSButton(title: "Finder", target: nil, action: nil)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        glass.opticalStyle = .crystal
        glass.cornerRadius = 32
        addSubview(glass)

        // Only this small label plate is opaque enough for white text.
        titlePlate.wantsLayer = true
        titlePlate.layer?.backgroundColor = NSColor(
            calibratedWhite: 0.08, alpha: 0.64).cgColor
        titlePlate.layer?.cornerRadius = 13
        glass.contentView.addSubview(titlePlate)

        title.font = .systemFont(ofSize: 16, weight: .semibold)
        title.textColor = .white
        detail.font = .systemFont(ofSize: 10.5, weight: .medium)
        detail.textColor = .white
        titlePlate.addSubview(title)
        titlePlate.addSubview(detail)

        // Rounded AppKit NSSearchFields can ignore their backgroundColor.
        // This small neutral backing keeps the field readable over any wallpaper.
        searchWell.wantsLayer = true
        searchWell.layer?.backgroundColor = NSColor(
            calibratedRed: 0.985, green: 0.990, blue: 1.0, alpha: 1).cgColor
        searchWell.layer?.cornerRadius = 9
        glass.contentView.addSubview(searchWell)
        GlassReadableSearchField.apply(
            to: search, placeholder: "Suchen (Demo)")
        search.setAccessibilityLabel("Suche innerhalb der Demo")
        search.target = self
        search.action = #selector(searchDidSubmit(_:))
        searchWell.addSubview(search)

        for item in GlassOpticalStyle.allCases {
            style.addItem(withTitle: item.title)
        }
        style.selectItem(at: 0)
        style.appearance = NSAppearance(named: .aqua)
        style.setAccessibilityLabel("Optischer Stil")
        style.target = self
        style.action = #selector(styleDidChange(_:))
        glass.contentView.addSubview(style)

        reflection.appearance = NSAppearance(named: .aqua)
        reflection.setAccessibilityLabel("Lichtreflexe umschalten")
        reflection.target = self
        reflection.action = #selector(reflectionDidChange(_:))
        glass.contentView.addSubview(reflection)

        finder.appearance = NSAppearance(named: .aqua)
        finder.setAccessibilityLabel("Finder öffnen")
        finder.target = self
        finder.action = #selector(openFinder(_:))
        glass.contentView.addSubview(finder)
    }

    required init?(coder: NSCoder) { nil }

    override func layout() {
        super.layout()
        // One native glass element; no fake menu bar or extra floating panels.
        glass.frame = NSRect(x: 43, y: 55,
                             width: bounds.width - 86, height: 148)
        titlePlate.frame = NSRect(x: 19, y: 16, width: 282, height: 55)
        title.frame = NSRect(x: 13, y: 8, width: 260, height: 24)
        detail.frame = NSRect(x: 13, y: 31, width: 264, height: 15)
        searchWell.frame = NSRect(x: 19, y: 87, width: 218, height: 32)
        search.frame = NSRect(x: 2, y: 1, width: 214, height: 30)
        style.frame = NSRect(x: 250, y: 87, width: 118, height: 32)
        reflection.frame = NSRect(x: 380, y: 88, width: 132, height: 30)
        finder.frame = NSRect(x: 525, y: 87, width: 91, height: 32)
    }

    @objc private func searchDidSubmit(_ sender: NSSearchField) {
        let query = sender.stringValue.trimmingCharacters(
            in: .whitespacesAndNewlines)
        detail.stringValue = query.isEmpty
            ? "Native, leicht, ohne Bildschirmaufnahme"
            : "Suche: " + String(query.prefix(24))
    }

    @objc private func styleDidChange(_ sender: NSPopUpButton) {
        glass.opticalStyle = GlassOpticalStyle(
            rawValue: sender.indexOfSelectedItem) ?? .crystal
    }

    @objc private func reflectionDidChange(_ sender: NSButton) {
        glass.showHighlights.toggle()
        sender.title = glass.showHighlights ? "Reflexe: An" : "Reflexe: Aus"
    }

    @objc private func openFinder(_ sender: NSButton) {
        NSWorkspace.shared.open(URL(
            fileURLWithPath: NSHomeDirectory(), isDirectory: true))
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
// The AppKit event loop starts on the main thread.
private let delegate = MainActor.assumeIsolated { GlassDemoApp() }
app.delegate = delegate
app.run()
