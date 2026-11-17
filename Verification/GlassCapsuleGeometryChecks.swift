import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

var passed = 0
let sizes = [CGSize(width: 320, height: 240), CGSize(width: 1024, height: 640),
             CGSize(width: 2200, height: 1000)]
for size in sizes {
    for pct in 0...200 {
        let scale = CGFloat(pct) / 100
        let rect = GlassCapsuleGeometry.centered(in: size, scale: scale)
        precondition(rect.origin.x >= -0.0001 && rect.origin.y >= -0.0001)
        precondition((rect.origin.x + rect.size.width) <= size.width + 0.0001)
        precondition((rect.origin.y + rect.size.height) <= size.height + 0.0001)
        precondition(rect.size.width >= 0 && rect.size.height >= 0)
        passed += 5
        let raw = CGRect(x: CGFloat(pct) * 8 - 200,
                         y: CGFloat(pct) * 5 - 250,
                         width: CGFloat(pct) * 3,
                         height: CGFloat(pct) * 4)
        let contained = GlassCapsuleGeometry.contained(raw, in: size)
        precondition(contained.origin.x >= 0 && contained.origin.y >= 0)
        precondition((contained.origin.x + contained.size.width) <= size.width + 0.0001)
        precondition((contained.origin.y + contained.size.height) <= size.height + 0.0001)
        passed += 4
    }
}
print("PASS GlassCapsuleGeometry: \(passed) invariants")
