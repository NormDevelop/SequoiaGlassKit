import SequoiaGlassKit
import AppKit
import Metal

/// A practical AppKit integration: a same-frame Metal background + a real,
/// keyboard-accessible native button layer inside a separately configured lens.
///
/// This samples only pixels drawn by `renderer.encodeContent`. Controls are real
/// NSButtons above the Metal view: they do not get captured, mirrored or delayed.
/// This is NOT a compositor for arbitrary Finder / desktop windows or SwiftUI trees.
public final class GlassControlsView: NSView {
    public override var isFlipped: Bool { true }

    public let renderer: SynchronizedGlassView
    private let titleLabel = NSTextField(labelWithString: "Glass control")
    private let detailLabel = NSTextField(labelWithString: "Same-frame Metal")
    private let actionButton = NSButton(title: "Play", target: nil, action: nil)
    private let secondaryButton = NSButton(title: "Next", target: nil, action: nil)

    /// Actions are only invoked by the real native controls.
    /// Request an offscreen redraw after host content changes.
    public func requestContentFrame() { renderer.requestContentFrame() }

    public var onPrimaryAction: (() -> Void)?
    public var onSecondaryAction: (() -> Void)?
    private var accessibilityObserver: NSObjectProtocol?
    public var glassEnabled = true { didSet { applyAccessibilityPreferences() } }

    public var title: String = "Glass control" { didSet { titleLabel.stringValue = title } }
    public var subtitle: String = "Same-frame Metal" { didSet { detailLabel.stringValue = subtitle } }
    public var primaryButtonTitle: String = "Play" {
        didSet { actionButton.title = primaryButtonTitle }
    }
    public var secondaryButtonTitle: String = "Next" {
        didSet { secondaryButton.title = secondaryButtonTitle }
    }
    public var lensScale: CGFloat = 0.75 {
        didSet { needsLayout = true }
    }
    public var lensCornerRadius: CGFloat = 34 {
        didSet { renderer.lensCornerRadius = lensCornerRadius }
    }

    public override init(frame frameRect: NSRect) {
        renderer = SynchronizedGlassView(frame: .zero, device: nil)
        super.init(frame: frameRect)
        setup()
    }

    public required init?(coder: NSCoder) { return nil }

    private func setup() {
        wantsLayer = true
        renderer.refractionPoints = 7
        renderer.rimIntensity = 0.22
        renderer.quality = .balanced
        renderer.glassScale = 0.75
        renderer.selectFrameRate(30)
        renderer.playbackPaused = true
        addSubview(renderer)

        titleLabel.font = .systemFont(ofSize: 19, weight: .semibold)
        titleLabel.textColor = .white
        detailLabel.font = .systemFont(ofSize: 12, weight: .regular)
        detailLabel.textColor = NSColor(calibratedWhite: 0.86, alpha: 1)

        for label in [titleLabel, detailLabel] {
            label.lineBreakMode = .byTruncatingTail
            addSubview(label)
        }
        for (button, action) in [(actionButton, #selector(primaryTapped(_:))),
                                 (secondaryButton, #selector(secondaryTapped(_:)))] {
            button.target = self
            button.action = action
            button.bezelStyle = .rounded
            button.font = .systemFont(ofSize: 13, weight: .semibold)
            // NSButton already exposes native button accessibility and keyboard actions.
            addSubview(button)
        }
        actionButton.setAccessibilityLabel("Primary glass control action")
        secondaryButton.setAccessibilityLabel("Secondary glass control action")
        accessibilityObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: NSWorkspace.shared, queue: .main) { [weak self] _ in
                self?.applyAccessibilityPreferences()
            }
        applyAccessibilityPreferences()
    }

    deinit {
        if let observer = accessibilityObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    private func applyAccessibilityPreferences() {
        // Apple's documented setting is a user preference, not merely a theme.
        // Never force a transparent lens when Reduce Transparency is enabled.
        renderer.isGlassVisible = glassEnabled &&
            !NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    }

    public override func layout() {
        super.layout()
        renderer.frame = bounds
        guard bounds.width > 0 && bounds.height > 0 else { return }
        // Use explicit lens geometry so controls stay aligned when the window resizes.
        let capsule = GlassCapsuleGeometry.centered(in: bounds.size, scale: lensScale)
        renderer.lensFrame = capsule
        renderer.lensCornerRadius = lensCornerRadius
        let textX = capsule.minX + 25
        let labelsWidth = max(0, capsule.width - 225)
        titleLabel.frame = CGRect(x: textX, y: capsule.midY - 29,
                                  width: labelsWidth, height: 27)
        detailLabel.frame = CGRect(x: textX, y: capsule.midY + 4,
                                   width: labelsWidth, height: 21)
        actionButton.frame = CGRect(x: capsule.maxX - 175, y: capsule.midY - 17,
                                    width: 77, height: 34)
        secondaryButton.frame = CGRect(x: capsule.maxX - 92, y: capsule.midY - 17,
                                       width: 71, height: 34)
    }

    @objc private func primaryTapped(_ sender: NSButton) { onPrimaryAction?() }
    @objc private func secondaryTapped(_ sender: NSButton) { onSecondaryAction?() }
}
