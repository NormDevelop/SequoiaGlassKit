import Foundation

var verified = 0
func check(_ valid: @autoclosure () -> Bool, _ message: String) {
    guard valid() else { fputs("FAIL: \(message)\n", stderr); exit(1) }
    verified += 1
}
for fps in -20...200 {
    let value = SharedFrameBudget.requestedFPS(fps)
    check(value == 30 || value == 60, "bounded fps")
    check(value == (fps <= 30 ? 30 : 60), "requested fps selection")
}
for frame in (0 as UInt64)...120_000 {
    let slot = SharedFrameBudget.textureSlot(frame: frame)
    check(slot == Int(frame % 3), "stable texture ring")
    check((0..<3).contains(slot), "texture pool range")
    check(SharedFrameBudget.isSameFrame(scene: frame, glass: frame), "shared frame stamp")
    check(!SharedFrameBudget.isSameFrame(scene: frame, glass: frame + 1), "detect one-frame skew")
}
for fps in [15.0,30,45,60,75,120] {
    check(abs(SharedFrameBudget.observedFPS(completedFrames: 120,
        seconds: 120.0/fps) - fps) < 1e-8, "completed frame rate")
}
check(SharedFrameBudget.observedFPS(completedFrames: 3, seconds: 0) == 0, "zero-time guard")
check(SharedFrameBudget.observedFPS(completedFrames: 3, seconds: -0.5) == 0, "negative-time guard")
check(SharedFrameBudget.gpuDurationMilliseconds(start: 0, end: 1) == nil, "unavailable GPU timestamps")
check(SharedFrameBudget.gpuDurationMilliseconds(start: 2, end: 1) == nil, "out-of-order GPU timestamps")
check(abs((SharedFrameBudget.gpuDurationMilliseconds(start: 2, end: 2.005) ?? 0) - 5) < 1e-6,
      "GPU duration conversion")
print("PASS: \(verified) same-frame scheduling/buffering checks")
