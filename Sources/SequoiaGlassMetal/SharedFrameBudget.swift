import Foundation

/// Small Foundation-only scheduling helpers, independently testable without AppKit.
public enum SharedFrameBudget {
    /// A bounded display request; the screen may use a different actual cadence.
    public static func requestedFPS(_ fps: Int) -> Int { fps <= 30 ? 30 : 60 }

    /// Each submitted command buffer receives one of three dedicated source textures.
    public static func textureSlot(frame: UInt64, count: Int = 3) -> Int {
        precondition(count > 0)
        return Int(frame % UInt64(count))
    }

    /// FPS from *completed* frames across a measured time window.
    public static func observedFPS(completedFrames: UInt64, seconds: Double) -> Double {
        guard seconds > 0, seconds.isFinite else { return 0 }
        return Double(completedFrames) / seconds
    }

    public static func gpuDurationMilliseconds(start: Double, end: Double) -> Double? {
        guard start > 0, end >= start, start.isFinite, end.isFinite else { return nil }
        return (end-start)*1000
    }

    /// Minimal invariant for the synchronized path: both render passes are
    /// produced from the same logical source frame stamp.
    public static func isSameFrame(scene: UInt64, glass: UInt64) -> Bool { scene == glass }
}
