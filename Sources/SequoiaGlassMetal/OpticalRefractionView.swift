import AppKit
import Metal
import MetalKit
import CoreGraphics
import ImageIO

/// A reproducible in-app image for measuring pixel displacement. Does not read the screen.
public enum RefractionTestPattern: Int, CaseIterable, Identifiable {
    case calibrationGrid = 0
    case colorBars = 1
    case checkerboard = 2

    public var id: Int { rawValue }
    public var title: String {
        switch self {
        case .calibrationGrid: return "Precision grid"
        case .colorBars: return "Color stripes"
        case .checkerboard: return "Checkerboard"
        }
    }
}

/// Diagnostic rendering mode. Only app-owned texture pixels are sampled.
public enum RefractionDebugMode: UInt32, CaseIterable, Identifiable {
    case image = 0
    case displacementField = 1
    case difference = 2

    public var id: UInt32 { rawValue }
    public var title: String {
        switch self {
        case .image: return "Natural lens"
        case .displacementField: return "Displacement field"
        case .difference: return "Pixel difference"
        }
    }
}

public enum LensLayoutMode: UInt32, CaseIterable, Identifiable {
    case comparison = 0
    case single = 1
    public var id: UInt32 { rawValue }
    public var title: String { self == .comparison ? "A/B comparison" : "Single glass lens" }
}

/// fullScene retains the v0.7 behavior. transparentOverlay renders only the
/// optical lens and can be placed above an app-owned NSView of equal size.
public enum LensRenderMode: UInt32, CaseIterable, Identifiable {
    case fullScene = 0
    case transparentOverlay = 1
    public var id: UInt32 { rawValue }
}

public enum GlassQuality: UInt32, CaseIterable, Identifiable {
    case eco = 0
    case balanced = 1
    case high = 2
    public var id: UInt32 { rawValue }
    public var title: String {
        switch self { case .eco: return "Eco"; case .balanced: return "Balanced"; case .high: return "High" }
    }
}

public struct RefractionSettings: Equatable {
    public var bendPixels: Float
    public var glassScale: Float
    public var rimIntensity: Float
    public var blurSoftness: Float
    public var bandWidth: Float
    public var debugMode: RefractionDebugMode
    public var layoutMode: LensLayoutMode
    public var dispersion: Float
    public var tintOpacity: Float
    public var quality: GlassQuality
    public var renderMode: LensRenderMode

    public init(bendPixels: Float = 7, glassScale: Float = 1,
                rimIntensity: Float = 0.25, blurSoftness: Float = 0,
                bandWidth: Float = 62, debugMode: RefractionDebugMode = .image,
                layoutMode: LensLayoutMode = .comparison, dispersion: Float = 0.45,
                tintOpacity: Float = 0.012, quality: GlassQuality = .balanced,
                renderMode: LensRenderMode = .fullScene) {
        self.bendPixels = max(0, bendPixels)
        self.glassScale = max(0.5, min(1.6, glassScale))
        self.rimIntensity = max(0, min(1, rimIntensity))
        self.blurSoftness = max(0, min(1, blurSoftness))
        self.bandWidth = max(12, min(110, bandWidth))
        self.debugMode = debugMode
        self.layoutMode = layoutMode
        self.dispersion = max(0, min(1.5, dispersion))
        self.tintOpacity = max(0, min(0.04, tintOpacity))
        self.quality = quality
        self.renderMode = renderMode
    }
}

struct LensUniforms {
    var viewport: SIMD2<Float>
    var mouse: SIMD2<Float>
    var strength: Float
    var thickness: Float
    var rim: Float
    var softness: Float
    var bandWidth: Float
    var pixelScale: Float
    var debugMode: UInt32
    var isHovering: UInt32
    var layoutMode: UInt32
    var dispersion: Float
    var tintOpacity: Float
    var quality: UInt32
    var renderMode: UInt32
    var cropOrigin: SIMD2<Float>
    var cropExtent: SIMD2<Float>
    var flipSourceV: UInt32
    // v1.1: explicit lens placement. AppKit coordinates converted to shader pixels.
    var customCenter: SIMD2<Float>
    var customHalfExtent: SIMD2<Float>
    var customRadius: Float
    var customLensEnabled: UInt32
}

/// Standalone re-usable Metal-backed comparison component.
/// The host may assign its own MTLTexture to `contentTexture` (shader-readable RGBA).
/// The built-in grid/stripe samples are only for tests and should not ship as app UI.
/// A real-world integration must supply its OWN contents; cross-app/window pixels
/// are NOT available through the public Metal APIs used here.
public final class OpticalRefractionView: MTKView, MTKViewDelegate {
    // NSView.isOpaque is read-only; subclasses report opacity by overriding.
    public override var isOpaque: Bool {
        settings.renderMode != .transparentOverlay
    }
    public var settings = RefractionSettings() {
        didSet {
            if settings != oldValue {
                applyRenderMode()
                needsDisplay = true
            }
        }
    }
    public var pattern: RefractionTestPattern = .calibrationGrid {
        didSet {
            if pattern != oldValue {
                generatedTexture = nil
                needsDisplay = true
            }
        }
    }
    public var contentTexture: MTLTexture? {
        didSet { needsDisplay = true }
    }
    /// Optional lifetime owner for a host-provided texture and any associated
    /// pixel storage. Kept until the GPU command buffer completes.
    public var frameLifetime: AnyObject?

    /// Optional capsule bounds in local top-left view coordinates.
    /// Useful when an overlay must line up with an AppKit background material.
    public var lensFrame: CGRect? { didSet { needsDisplay = true } }
    public var lensCornerRadius: CGFloat = 40 { didSet { needsDisplay = true } }
    /// Region of the source view represented by `contentTexture`, in normalized
    /// top-left view coordinates. Leave at full area for still photos.
    public var sourceViewportRegion: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1) {
        didSet { needsDisplay = true }
    }
    /// Backward-compatible orientation toggle for host-provided source textures.
    /// The property name is historical; this SDK performs no screen capture.
    public var flipCapturedSourceVertically = false {
        didSet { needsDisplay = true }
    }
    /// App-owned image URL. Images are downsampled to 2048px before uploading to Metal.
    public private(set) var loadedImageURL: URL?
    /// GPU execution time for the latest completed render. Not a frame-rate estimate.
    public var onGPUTime: ((Double) -> Void)?

    public func loadImage(from url: URL) throws {
        guard loadedImageURL != url else { return }
        guard let device = device,
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw NSError(domain: "SequoiaGlassKit", code: 20,
              userInfo: [NSLocalizedDescriptionKey: "Unable to open this image."])
        }
        let options: [String: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways as String: true,
            kCGImageSourceCreateThumbnailWithTransform as String: true,
            kCGImageSourceThumbnailMaxPixelSize as String: 2048
        ]
        guard let bitmap = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw NSError(domain: "SequoiaGlassKit", code: 21,
              userInfo: [NSLocalizedDescriptionKey: "Image format unsupported."])
        }
        let loader = MTKTextureLoader(device: device)
        let texture = try loader.newTexture(cgImage: bitmap, options: [
            .SRGB: false,
            .origin: MTKTextureLoader.Origin.topLeft
        ])
        contentTexture = texture
        loadedImageURL = url
    }

    public func clearImage() {
        if contentTexture != nil || loadedImageURL != nil {
            contentTexture = nil
            loadedImageURL = nil
        }
    }

    private var engine: MetalLensEngine?
    private var generatedTexture: MTLTexture?
    private var pointer: CGPoint = .zero
    private var pointerInside = false
    private var tracking: NSTrackingArea?

    public override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device ?? MTLCreateSystemDefaultDevice())
        configure()
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)
        if device == nil { device = MTLCreateSystemDefaultDevice() }
        configure()
    }

    private func configure() {
        colorPixelFormat = .bgra8Unorm
        clearColor = MTLClearColor(red: 0.08, green: 0.12, blue: 0.2, alpha: 1)
        isPaused = true
        enableSetNeedsDisplay = true
        framebufferOnly = true
        preferredFramesPerSecond = 30
        delegate = self
        applyRenderMode()
        guard let device = device else {
            showError("Metal is unavailable on this Mac.")
            return
        }
        do {
            engine = try MetalLensEngine(device: device, pixelFormat: colorPixelFormat)
        } catch {
            showError("Metal shader failed: \(error.localizedDescription)")
        }
    }

    private func applyRenderMode() {
        let transparent = settings.renderMode == .transparentOverlay
        layer?.isOpaque = !transparent
        clearColor = transparent
            ? MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            : MTLClearColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 1)
    }

    private func showError(_ message: String) {
        let label = NSTextField(wrappingLabelWithString: message)
        label.textColor = NSColor.systemRed
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.85)
        ])
        NSLog("SequoiaGlassKit: %@", message)
    }

    public override func updateTrackingAreas() {
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: .zero,
                                  options: [.mouseMoved, .mouseEnteredAndExited,
                                            .activeInKeyWindow, .inVisibleRect],
                                  owner: self, userInfo: nil)
        addTrackingArea(area)
        tracking = area
        super.updateTrackingAreas()
    }

    /// A glass *overlay* must not steal mouse clicks from the real app controls
    /// underneath it. Full-scene diagnostics keep their normal event behavior.
    public override func hitTest(_ point: NSPoint) -> NSView? {
        if settings.renderMode == .transparentOverlay { return nil }
        return super.hitTest(point)
    }

    public override func mouseEntered(with event: NSEvent) {
        pointerInside = true
        mouseMoved(with: event)
    }
    public override func mouseExited(with event: NSEvent) {
        pointerInside = false
        needsDisplay = true
    }
    public override func mouseMoved(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        pointer = CGPoint(x: p.x, y: bounds.height - p.y)
        needsDisplay = true
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        needsDisplay = true
    }

    public func draw(in view: MTKView) {
        guard let engine = engine else { return }
        // The host can supply its own MTLTexture. Do not allocate the 1400x800
        // calibration texture unless the developer actually opens a pattern test.
        if contentTexture == nil && generatedTexture == nil {
            generatedTexture = engine.makeTestTexture(pattern: pattern)
        }
        guard let texture = contentTexture ?? generatedTexture else { return }
        let scaleX = bounds.width > 0 ? Float(drawableSize.width / bounds.width) : 1
        let scaleY = bounds.height > 0 ? Float(drawableSize.height / bounds.height) : 1
        let mouse = SIMD2<Float>(Float(pointer.x) * scaleX, Float(pointer.y) * scaleY)
        let customCenter = lensFrame.map { SIMD2<Float>(
            Float($0.midX) * scaleX, Float($0.midY) * scaleY) }
        let customHalf = lensFrame.map { SIMD2<Float>(
            Float($0.width * 0.5) * scaleX, Float($0.height * 0.5) * scaleY) }
        let uniform = LensUniforms(
            viewport: SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height)),
            mouse: mouse,
            strength: settings.bendPixels * scaleX,
            thickness: settings.glassScale,
            rim: settings.rimIntensity,
            softness: settings.blurSoftness,
            bandWidth: settings.bandWidth,
            pixelScale: scaleX,
            debugMode: settings.debugMode.rawValue,
            isHovering: pointerInside ? 1 : 0,
            layoutMode: settings.layoutMode.rawValue,
            dispersion: settings.dispersion,
            tintOpacity: settings.tintOpacity,
            quality: settings.quality.rawValue,
            renderMode: settings.renderMode.rawValue,
            cropOrigin: SIMD2<Float>(Float(sourceViewportRegion.minX),
                                     Float(sourceViewportRegion.minY)),
            cropExtent: SIMD2<Float>(Float(sourceViewportRegion.width),
                                     Float(sourceViewportRegion.height)),
            flipSourceV: flipCapturedSourceVertically ? 1 : 0,
            customCenter: customCenter ?? SIMD2<Float>(0,0),
            customHalfExtent: customHalf ?? SIMD2<Float>(0,0),
            customRadius: Float(lensCornerRadius) * min(scaleX, scaleY),
            customLensEnabled: lensFrame == nil ? 0 : 1
        )
        engine.draw(in: view, texture: texture, uniforms: uniform,
                    frameLifetime: frameLifetime, onGPUTime: onGPUTime)
    }
}

private final class MetalLensEngine {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState

    init(device: MTLDevice, pixelFormat: MTLPixelFormat) throws {
        self.device = device
        guard let queue = device.makeCommandQueue() else {
            throw NSError(domain: "SequoiaGlassKit", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Command queue unavailable"])
        }
        commandQueue = queue
        // Runtime compilation keeps SwiftPM builds possible with Command Line Tools only.
        let shaderLibrary = try device.makeLibrary(source: MetalLensShader.source, options: nil)
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = shaderLibrary.makeFunction(name: "fullscreenVertex")
        descriptor.fragmentFunction = shaderLibrary.makeFunction(name: "opticalFragment")
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func draw(in view: MTKView, texture: MTLTexture, uniforms: LensUniforms,
              frameLifetime: AnyObject?, onGPUTime: ((Double) -> Void)?) {
        guard let pass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let buffer = commandQueue.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentTexture(texture, index: 0)
        var parameterBlock = uniforms
        withUnsafeBytes(of: &parameterBlock) { bytes in
            if let base = bytes.baseAddress {
                encoder.setFragmentBytes(base, length: bytes.count, index: 0)
            }
        }
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        buffer.present(drawable)
        // Host-owned source storage must outlive the GPU read, even if the
        // app provides a different contentTexture in the next update.
        if let frameLifetime {
            buffer.addCompletedHandler { _ in
                withExtendedLifetime(frameLifetime) {}
            }
        }
        if let onGPUTime {
            buffer.addCompletedHandler { completed in
                let start = completed.gpuStartTime
                let end = completed.gpuEndTime
                guard start > 0, end >= start else { return }
                let ms = (end - start) * 1000.0
                DispatchQueue.main.async { onGPUTime(ms) }
            }
        }
        buffer.commit()
    }

    func makeTestTexture(pattern: RefractionTestPattern) -> MTLTexture? {
        let width = 1400
        let height = 800
        let bytesPerRow = width * 4
        let description = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        description.usage = [.shaderRead]
        guard let texture = device.makeTexture(descriptor: description) else { return nil }
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
        pixels.withUnsafeMutableBytes { raw in
            guard let data = raw.baseAddress,
                  let context = CGContext(data: data, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |
                                                      CGBitmapInfo.byteOrder32Big.rawValue) else { return }
            drawReferencePattern(context, width: width, height: height, pattern: pattern)
            texture.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0,
                            withBytes: data, bytesPerRow: bytesPerRow)
        }
        return texture
    }

    private func drawReferencePattern(_ ctx: CGContext, width: Int, height: Int,
                                      pattern: RefractionTestPattern) {
        let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [CGColor(red: 0.08, green: 0.14, blue: 0.23, alpha: 1),
                                           CGColor(red: 0.12, green: 0.32, blue: 0.42, alpha: 1)] as CFArray,
                                  locations: [0, 1])!
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: 0),
                               end: CGPoint(x: CGFloat(width), y: CGFloat(height)), options: [])
        ctx.setFillColor(CGColor(red: 0.93, green: 0.96, blue: 0.98, alpha: 1))
        switch pattern {
        case .calibrationGrid:
            for x in stride(from: 0, through: width, by: 24) {
                let bright = x % 96 == 0
                ctx.setStrokeColor(CGColor(red: 0.90, green: 0.96, blue: 1,
                                           alpha: bright ? 0.70 : 0.24))
                ctx.setLineWidth(bright ? 2.4 : 1)
                ctx.move(to: CGPoint(x: CGFloat(x), y: 0))
                ctx.addLine(to: CGPoint(x: CGFloat(x), y: CGFloat(height)))
                ctx.strokePath()
            }
            for y in stride(from: 0, through: height, by: 24) {
                let bright = y % 96 == 0
                ctx.setStrokeColor(CGColor(red: 0.92, green: 0.97, blue: 1,
                                           alpha: bright ? 0.65 : 0.22))
                ctx.setLineWidth(bright ? 2.4 : 1)
                ctx.move(to: CGPoint(x: 0, y: CGFloat(y)))
                ctx.addLine(to: CGPoint(x: CGFloat(width), y: CGFloat(y)))
                ctx.strokePath()
            }
        case .colorBars:
            let colors: [CGColor] = [
                CGColor(red: 0.22, green: 0.72, blue: 0.92, alpha: 1),
                CGColor(red: 0.98, green: 0.72, blue: 0.35, alpha: 1),
                CGColor(red: 0.96, green: 0.39, blue: 0.43, alpha: 1),
                CGColor(red: 0.42, green: 0.83, blue: 0.65, alpha: 1)
            ]
            for x in stride(from: 0, through: width, by: 34) {
                ctx.setFillColor(colors[(x / 34) % colors.count])
                ctx.fill(CGRect(x: CGFloat(x), y: 0, width: 17, height: CGFloat(height)))
            }
            for y in stride(from: 0, through: height, by: 68) {
                ctx.setFillColor(CGColor(red: 0.04, green: 0.11, blue: 0.21, alpha: 0.24))
                ctx.fill(CGRect(x: 0, y: CGFloat(y), width: CGFloat(width), height: 15))
            }
        case .checkerboard:
            for y in stride(from: 0, to: height, by: 46) {
                for x in stride(from: 0, to: width, by: 46) {
                    if (x / 46 + y / 46) % 2 == 0 {
                        ctx.setFillColor(CGColor(red: 0.92, green: 0.95, blue: 0.92, alpha: 1))
                    } else {
                        ctx.setFillColor(CGColor(red: 0.07, green: 0.17, blue: 0.25, alpha: 1))
                    }
                    ctx.fill(CGRect(x: CGFloat(x), y: CGFloat(y), width: 46, height: 46))
                }
            }
        }
        // A repeated orange calibration marker crossing both lens regions.
        for x in [width / 4, width * 3 / 4] {
            ctx.setStrokeColor(CGColor(red: 1, green: 0.38, blue: 0.19, alpha: 0.9))
            ctx.setLineWidth(7)
            ctx.move(to: CGPoint(x: CGFloat(x), y: 0))
            ctx.addLine(to: CGPoint(x: CGFloat(x), y: CGFloat(height)))
            ctx.strokePath()
        }
        ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.8))
        ctx.setLineWidth(2)
        ctx.stroke(rect.insetBy(dx: 3, dy: 3))
    }
}
