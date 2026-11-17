import SequoiaGlassKit
import AppKit
import Metal
import MetalKit

/// Statistics for one completed GPU frame. A single command buffer contains
/// both source rendering and optical composition; there is no stale CPU capture.
public struct SynchronizedGlassStatistics {
    public let frameIndex: UInt64
    public let encodedMilliseconds: Double
    public let gpuMilliseconds: Double?
    public let observedFramesPerSecond: Double
    public let droppedFrames: UInt64
    public let textureWidth: Int
    public let textureHeight: Int
}

/// A production-oriented Metal glass compositor for host-owned GPU content.
///
/// Render stages within one command buffer:
/// 1. `encodeContent` (or the built-in animated test pattern) draws to a private
///    offscreen texture.
/// 2. The optical shader reads THAT SAME texture and presents the glass and
///    non-glass content in the same drawable / time step.
///
/// A host supplies `encodeContent`: it receives an already-open render encoder
/// with its color attachment set to this frame's source texture. The callback
/// may draw its own geometry, but MUST NOT call `endEncoding()` on the encoder.
/// Avoid capturing `self` strongly from that callback (retain cycle).
///
/// This is intentionally for content already rendered by the host into Metal.
/// Arbitrary NSViews and SwiftUI hierarchies are not automatically readable as
/// source textures; the host must encode its own content into this render pass.
/// No screen-recording entitlement, external window access or private API.
public final class SynchronizedGlassView: MTKView, MTKViewDelegate {
    /// Optional custom content producer. Runs on the main thread, inside the
    /// SAME command buffer as the optical shader. Avoid expensive CPU work.
    public var encodeContent: ((MTLRenderCommandEncoder, CGSize, Double) -> Void)? {
        didSet { requestContentFrame() }
    }

    /// Statistics arrive on the main thread and are safe to bind to AppKit.
    public var onStatistics: ((SynchronizedGlassStatistics) -> Void)?
    public var onError: ((String) -> Void)? {
        didSet { if let message = startupError { onError?(message) } }
    }

    public var refractionPoints: Float = 7 {
        didSet { refractionPoints = max(0, min(12, refractionPoints)); requestRefresh() }
    }
    public var isGlassVisible = true { didSet { requestRefresh() } }
    public var rimIntensity: Float = 0.20 {
        didSet { rimIntensity = max(0, min(1, rimIntensity)); requestRefresh() }
    }
    public var glassScale: Float = 0.75 {
        didSet { glassScale = max(0.55, min(1.4, glassScale)); requestRefresh() }
    }

    /// Optional lens frame in local VIEW POINTS with a top-left origin.
    /// Unlike v1.0, the lens is no longer restricted to a hardcoded center.
    /// nil retains the original default demo placement.
    public var lensFrame: CGRect? { didSet { requestRefresh() } }
    public var lensCornerRadius: CGFloat = 36 { didSet { requestRefresh() } }

    public var quality: GlassQuality = .balanced { didSet { requestRefresh() } }
    public var playbackPaused = true {
        didSet {
            if playbackPaused {
                frozenTime = ProcessInfo.processInfo.systemUptime-animationOrigin
            } else {
                animationOrigin = ProcessInfo.processInfo.systemUptime-frozenTime
                lastCompletionUptime = 0
                lastReportedFrame = submittedFrames
            }
            isPaused = playbackPaused
            enableSetNeedsDisplay = playbackPaused
            requestRefresh()
        }
    }

    public func selectFrameRate(_ fps: Int) {
        preferredFramesPerSecond = SharedFrameBudget.requestedFPS(fps)
    }

    private var startupError: String?
    private var queue: MTLCommandQueue?
    private var lensPipeline: MTLRenderPipelineState?
    private var textures: [MTLTexture] = []
    private var cachedWidth = 0
    private var cachedHeight = 0
    private let availableFrames = DispatchSemaphore(value: 3)
    private var submittedFrames: UInt64 = 0
    private var droppedFrames: UInt64 = 0
    private var animationOrigin = ProcessInfo.processInfo.systemUptime
    private var frozenTime: Double = 0
    private var lastCompletionUptime: Double = 0
    private var lastReportedFrame: UInt64 = 0

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
        framebufferOnly = true
        autoResizeDrawable = true
        sampleCount = 1
        isPaused = true
        enableSetNeedsDisplay = true
        preferredFramesPerSecond = 30
        clearColor = MTLClearColor(red: 0.05, green: 0.11, blue: 0.18, alpha: 1)
        delegate = self
        guard let device = device, let commandQueue = device.makeCommandQueue() else {
            report("Metal device or command queue unavailable")
            return
        }
        queue = commandQueue
        do {
            // One library, two pipelines. Runtime compile works without full Xcode.
            let library = try device.makeLibrary(
                source: MetalLensShader.source,
                options: nil)
            let glass = MTLRenderPipelineDescriptor()
            glass.vertexFunction = library.makeFunction(name: "fullscreenVertex")
            glass.fragmentFunction = library.makeFunction(name: "opticalFragment")
            glass.colorAttachments[0].pixelFormat = colorPixelFormat
            lensPipeline = try device.makeRenderPipelineState(descriptor: glass)
        } catch {
            report("Metal runtime compilation failed: \(error.localizedDescription)")
        }
    }

    private func report(_ message: String) {
        startupError = message
        NSLog("SequoiaGlassMetal: %@", message)
        onError?(message)
    }

    /// Explicit redraw for host-owned content. Does not initiate a display loop.
    public func requestContentFrame() { needsDisplay = true }

    private func requestRefresh() {
        if playbackPaused { needsDisplay = true }
    }

    private func allocateTextures(width: Int, height: Int, device: MTLDevice) -> Bool {
        if cachedWidth == width && cachedHeight == height && textures.count == 3 { return true }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        let generated = (0..<3).compactMap { _ in device.makeTexture(descriptor: descriptor) }
        guard generated.count == 3 else {
            report("Unable to allocate three GPU source textures")
            return false
        }
        textures = generated
        cachedWidth = width
        cachedHeight = height
        return true
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        cachedWidth = 0
        cachedHeight = 0
        requestRefresh()
    }

    public func draw(in view: MTKView) {
        // Never synthesize a scene or keep rendering when the host did not supply pixels.
        guard let encodeContent = encodeContent else { return }
        guard let gpu = device,
              let queue = queue,
              let lensPipeline = lensPipeline else { return }
        // NEVER block the UI while awaiting GPU work; skip a frame instead.
        guard availableFrames.wait(timeout: .now()) == .success else {
            droppedFrames += 1
            return
        }
        let size = drawableSize
        let width = Int(size.width), height = Int(size.height)
        guard width > 1, height > 1,
              allocateTextures(width: width, height: height, device: gpu),
              let displayPass = currentRenderPassDescriptor,
              let drawable = currentDrawable,
              let commandBuffer = queue.makeCommandBuffer() else {
            availableFrames.signal()
            return
        }
        let start = ProcessInfo.processInfo.systemUptime
        let timestamp = playbackPaused ? frozenTime : start-animationOrigin
        let index = SharedFrameBudget.textureSlot(frame: submittedFrames)
        let sceneTexture = textures[index]

        let firstPass = MTLRenderPassDescriptor()
        firstPass.colorAttachments[0].texture = sceneTexture
        firstPass.colorAttachments[0].loadAction = .clear
        firstPass.colorAttachments[0].storeAction = .store
        firstPass.colorAttachments[0].clearColor = MTLClearColor(red: 0.06, green: 0.12, blue: 0.19, alpha: 1)
        guard let sourceEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: firstPass) else {
            availableFrames.signal()
            return
        }
        encodeContent(sourceEncoder, size, timestamp)
        sourceEncoder.endEncoding()

        guard let outputEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: displayPass) else {
            availableFrames.signal()
            return
        }
        outputEncoder.setRenderPipelineState(lensPipeline)
        outputEncoder.setFragmentTexture(sceneTexture, index: 0)
        let scaleX = Float(size.width / max(bounds.width, 1))
        let scaleY = Float(size.height / max(bounds.height, 1))
        // The GPU shader expects a top-left origin; AppKit views may be flipped.
        let geometry = lensFrame
        let customCenter = geometry.map { SIMD2<Float>(
            Float($0.midX) * scaleX, Float($0.midY) * scaleY) } ?? SIMD2<Float>(0, 0)
        let customHalf = geometry.map { SIMD2<Float>(
            Float($0.width * 0.5) * scaleX, Float($0.height * 0.5) * scaleY) } ?? SIMD2<Float>(0, 0)
        var optics = LensUniforms(
            viewport: SIMD2<Float>(Float(width),Float(height)),
            mouse: SIMD2<Float>(Float(width/2),Float(height/2)),
            strength: isGlassVisible ? refractionPoints * Float(size.width/max(bounds.width,1)) : 0,
            thickness: glassScale,
            rim: isGlassVisible ? rimIntensity : 0,
            softness: 0,
            bandWidth: 54,
            pixelScale: Float(size.width/max(bounds.width,1)),
            debugMode: RefractionDebugMode.image.rawValue,
            isHovering: 0,
            layoutMode: LensLayoutMode.single.rawValue,
            dispersion: 0.25,
            tintOpacity: isGlassVisible ? 0.008 : 0,
            quality: quality.rawValue,
            renderMode: LensRenderMode.fullScene.rawValue,
            cropOrigin: SIMD2<Float>(0,0),
            cropExtent: SIMD2<Float>(1,1),
            flipSourceV: 0,
            customCenter: customCenter,
            customHalfExtent: customHalf,
            customRadius: Float(max(1, lensCornerRadius)) * min(scaleX, scaleY),
            customLensEnabled: geometry == nil ? 0 : 1)
        // When glass is disabled, the shader's rim is zero but the original
        // shape remains; 0 bend/tint makes it effectively an identity pass.
        if !isGlassVisible { optics.quality = GlassQuality.eco.rawValue }
        withUnsafeBytes(of: &optics) { bytes in
            if let base = bytes.baseAddress {
                outputEncoder.setFragmentBytes(base, length: bytes.count, index: 0)
            }
        }
        outputEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        outputEncoder.endEncoding()
        commandBuffer.present(drawable)
        submittedFrames += 1
        let frameNumber = submittedFrames
        let skipped = droppedFrames
        let encodeMilliseconds = (ProcessInfo.processInfo.systemUptime-start)*1000.0
        let freeSlot = availableFrames
        commandBuffer.addCompletedHandler { [weak self] result in
            // The frame's source and lens have completed together.
            freeSlot.signal()
            let begin = result.gpuStartTime, end = result.gpuEndTime
            let gpuTime = SharedFrameBudget.gpuDurationMilliseconds(start: begin, end: end)
            // Report only every 12th submitted frame; avoid 60 UI callbacks/s.
            guard frameNumber % 12 == 0 else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let now = ProcessInfo.processInfo.systemUptime
                let framesSinceReport = frameNumber > self.lastReportedFrame
                    ? frameNumber-self.lastReportedFrame : 0
                let fps = self.lastCompletionUptime > 0
                    ? SharedFrameBudget.observedFPS(completedFrames: framesSinceReport,
                        seconds: now-self.lastCompletionUptime) : 0
                self.lastCompletionUptime = now
                self.lastReportedFrame = frameNumber
                self.onStatistics?(SynchronizedGlassStatistics(
                    frameIndex: frameNumber, encodedMilliseconds: encodeMilliseconds,
                    gpuMilliseconds: gpuTime, observedFramesPerSecond: fps,
                    droppedFrames: skipped, textureWidth: width, textureHeight: height))
            }
        }
        commandBuffer.commit()
    }
}

