import AppKit
import QuartzCore

/// Optional appearance override; default is the actual macOS appearance.
public enum GlassSurfaceAppearance: Equatable {
    case system, light, dark
}

private final class GlassFlippedContentView: NSView {
    override var isFlipped: Bool { true }
}

/// Ultra-light optical surface for application-owned controls on macOS 13+.
///
/// Crystal draws a physically *suggestive* rim over actual transparent window
/// pixels. It DOES NOT refract the pixels of Finder or other apps. On macOS 15
/// there is no public, capture-free API for that proprietary Liquid Glass effect.
/// The optional SequoiaGlassMetal module can refract app-owned GPU textures.
///
/// No screen capture, timers, display-link, polling or private APIs.
@MainActor
public final class SystemGlassSurfaceView: NSView {
    public override var isFlipped: Bool { true }
    public let effect = NSVisualEffectView(frame: .zero)
    public let contentView: NSView = GlassFlippedContentView(frame: .zero)

    public var cornerRadius: CGFloat = 30 { didSet { needsLayout = true } }
    public var opticalStyle: GlassOpticalStyle = .crystal { didSet { applyAppearance() } }
    public var appearanceMode: GlassSurfaceAppearance = .system { didSet { applyAppearance() } }
    public var showHighlights = true { didSet { updateMaterial() } }
    public var nativeMaterialEnabled = true { didSet { updateMaterial() } }
    public var appearanceMaterial: NSVisualEffectView.Material = .popover { didSet { updateMaterial() } }
    /// Optional for integrations upgrading from v1.9.
    @available(*, deprecated, message: "Use appearanceMode instead")
    public var useLightAppearance: Bool {
        get { if case .light = appearanceMode { return true }; return false }
        set { appearanceMode = newValue ? .light : .system }
    }

    private let opaqueFallback = CALayer()
    private let neutralSheen = CALayer()
    private let perimeterBand = CAGradientLayer()
    private let perimeterBandMask = CAShapeLayer()
    private let specularRim = CAGradientLayer()
    private let specularMask = CAShapeLayer()
    private let pointerGlint = CAGradientLayer()
    private let glintMask = CAShapeLayer()
    private let innerLine = CAShapeLayer()
    private var observer: NSObjectProtocol?
    private var tracking: NSTrackingArea?
    private var pointerFraction: CGFloat = 0.37

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        guard let root = layer else { return }
        root.masksToBounds = false
        effect.wantsLayer = true
        effect.blendingMode = .behindWindow
        effect.state = .active
        addSubview(effect)

        opaqueFallback.isHidden = true
        root.addSublayer(opaqueFallback)
        root.addSublayer(neutralSheen)

        perimeterBand.startPoint = CGPoint(x: 0.5, y: 1)
        perimeterBand.endPoint = CGPoint(x: 0.5, y: 0)
        perimeterBand.locations = [0, 0.14, 0.50, 0.84, 1]
        perimeterBand.mask = perimeterBandMask
        perimeterBandMask.fillRule = .evenOdd
        perimeterBandMask.fillColor = NSColor.white.cgColor
        root.addSublayer(perimeterBand)

        specularRim.startPoint = CGPoint(x: 0.5, y: 1)
        specularRim.endPoint = CGPoint(x: 0.5, y: 0)
        specularRim.locations = [0, 0.13, 0.42, 0.85, 1]
        specularMask.fillColor = NSColor.clear.cgColor
        specularMask.strokeColor = NSColor.white.cgColor
        specularMask.lineWidth = 1.6
        specularRim.mask = specularMask
        root.addSublayer(specularRim)

        pointerGlint.startPoint = CGPoint(x: 0, y: 0.5)
        pointerGlint.endPoint = CGPoint(x: 1, y: 0.5)
        glintMask.fillColor = NSColor.clear.cgColor
        glintMask.strokeColor = NSColor.white.cgColor
        glintMask.lineWidth = 2.7
        pointerGlint.mask = glintMask
        root.addSublayer(pointerGlint)

        innerLine.fillColor = NSColor.clear.cgColor
        innerLine.lineWidth = 0.6
        root.addSublayer(innerLine)

        addSubview(contentView)
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: NSWorkspace.shared,
            queue: .main
        ) { [weak self] _ in
            // NSView / Core Animation must be manipulated on the main actor.
            MainActor.assumeIsolated { self?.updateMaterial() }
        }
        applyAppearance()
    }

    public required init?(coder: NSCoder) { nil }

    deinit {
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateMaterial()
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        tracking = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil)
        if let tracking { addTrackingArea(tracking) }
    }

    public override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        guard bounds.width > 1 else { return }
        let p = convert(event.locationInWindow, from: nil)
        pointerFraction = max(0.18, min(0.82, p.x / bounds.width))
        updateGlint()
    }

    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        pointerFraction = 0.37
        updateGlint()
    }

    private func applyAppearance() {
        switch appearanceMode {
        case .system: effect.appearance = nil
        case .light: effect.appearance = NSAppearance(named: .aqua)
        case .dark: effect.appearance = NSAppearance(named: .darkAqua)
        }
        updateMaterial()
    }

    private func updateGlint() {
        // The gradient follows a pointer *event*, not a 60-FPS timer.
        let x = Double(pointerFraction)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pointerGlint.locations = [0, NSNumber(value: max(0.0, x - 0.19)),
                                  NSNumber(value: x),
                                  NSNumber(value: min(1.0, x + 0.14)), 1]
        CATransaction.commit()
    }

    private func updateMaterial() {
        guard let root = layer else { return }
        let p = GlassOpticsProfile(style: opticalStyle)
        let reduceTransparency = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        let increaseContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        let dark = appearanceMode == .dark || (appearanceMode == .system &&
            effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua)
        let useNativeBlur = p.nativeBlurOpacity > 0 && nativeMaterialEnabled && !reduceTransparency
        effect.material = appearanceMaterial
        effect.state = .active
        effect.isHidden = !useNativeBlur
        effect.alphaValue = CGFloat(p.nativeBlurOpacity)

        opaqueFallback.isHidden = !reduceTransparency
        opaqueFallback.backgroundColor = (dark
            ? NSColor(white: 0.13, alpha: 1)
            : NSColor(white: 0.96, alpha: 1)).cgColor
        neutralSheen.isHidden = reduceTransparency
        neutralSheen.backgroundColor = NSColor(white: 1,
            alpha: CGFloat(p.neutralOverlayOpacity)).cgColor

        let enabled = showHighlights && !reduceTransparency
        perimeterBand.isHidden = !enabled
        specularRim.isHidden = !enabled
        pointerGlint.isHidden = !enabled
        innerLine.isHidden = !enabled
        perimeterBand.opacity = Float(p.edgeBandOpacity)
        specularRim.opacity = Float(p.upperRimOpacity)
        pointerGlint.opacity = Float(p.upperRimOpacity)
        innerLine.opacity = Float(p.innerRimOpacity)

        // In natural glass, the top rim is luminous, the bottom rim is dimmer.
        perimeterBand.colors = [
            NSColor.white.withAlphaComponent(dark ? 0.22 : 0.20).cgColor,
            NSColor.white.withAlphaComponent(dark ? 0.11 : 0.085).cgColor,
            NSColor.clear.cgColor,
            NSColor.black.withAlphaComponent(0.025).cgColor,
            NSColor.black.withAlphaComponent(0.06).cgColor
        ]
        specularRim.colors = [
            NSColor.white.withAlphaComponent(dark ? 0.93 : 0.89).cgColor,
            NSColor.white.withAlphaComponent(0.32).cgColor,
            NSColor.white.withAlphaComponent(0.045).cgColor,
            NSColor.white.withAlphaComponent(0.13).cgColor,
            NSColor.white.withAlphaComponent(0.22).cgColor
        ]
        pointerGlint.colors = [
            NSColor.clear.cgColor, NSColor.white.withAlphaComponent(0.015).cgColor,
            NSColor.white.withAlphaComponent(dark ? 0.82 : 0.75).cgColor,
            NSColor.white.withAlphaComponent(0.02).cgColor, NSColor.clear.cgColor
        ]
        innerLine.strokeColor = NSColor.white.withAlphaComponent(dark ? 0.42 : 0.26).cgColor

        root.shadowColor = NSColor.black.cgColor
        root.shadowOpacity = Float(reduceTransparency ? 0 : p.shadowOpacity)
        root.shadowRadius = increaseContrast ? 11 : 15
        root.shadowOffset = CGSize(width: 0, height: -6)
        updateGlint()
    }

    public override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let r = min(cornerRadius, bounds.width * 0.5, bounds.height * 0.5)
        effect.frame = bounds
        effect.layer?.cornerRadius = r
        effect.layer?.masksToBounds = true
        opaqueFallback.frame = bounds
        opaqueFallback.cornerRadius = r
        neutralSheen.frame = bounds
        neutralSheen.cornerRadius = r

        let outer = bounds.insetBy(dx: 0.55, dy: 0.55)
        let inner = bounds.insetBy(dx: 5, dy: 5)
        let band = CGMutablePath()
        band.addRoundedRect(in: outer, cornerWidth: max(1, r - 0.5),
                            cornerHeight: max(1, r - 0.5))
        band.addRoundedRect(in: inner, cornerWidth: max(1, r - 5),
                            cornerHeight: max(1, r - 5))
        perimeterBand.frame = bounds
        perimeterBandMask.frame = bounds
        perimeterBandMask.path = band

        let outline = CGPath(roundedRect: bounds.insetBy(dx: 1.35, dy: 1.35),
                             cornerWidth: max(1, r - 1.35),
                             cornerHeight: max(1, r - 1.35), transform: nil)
        specularRim.frame = bounds
        specularMask.frame = bounds
        specularMask.path = outline
        pointerGlint.frame = bounds
        glintMask.frame = bounds
        glintMask.path = outline
        innerLine.frame = bounds
        innerLine.path = CGPath(roundedRect: inner,
                                cornerWidth: max(1, r - 5),
                                cornerHeight: max(1, r - 5), transform: nil)
        contentView.frame = bounds
        layer?.shadowPath = CGPath(roundedRect: outer,
                                   cornerWidth: max(1, r - 0.5),
                                   cornerHeight: max(1, r - 0.5), transform: nil)
        CATransaction.commit()
    }
}
