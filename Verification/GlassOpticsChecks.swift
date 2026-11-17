import Foundation

var count = 0
for style in GlassOpticalStyle.allCases {
    let p = GlassOpticsProfile(style: style)
    let values = [p.nativeBlurOpacity, p.neutralOverlayOpacity,
                  p.upperRimOpacity, p.innerRimOpacity,
                  p.edgeBandOpacity, p.shadowOpacity]
    for v in values {
        precondition(v.isFinite && v >= 0 && v <= 1,
                     "Invalid profile parameter for \(style.title)")
        count += 1
    }
    precondition(p.neutralOverlayOpacity <= 0.025,
                 "Avoid opaque/brown overlays")
    precondition(p.upperRimOpacity > p.innerRimOpacity,
                 "Top rim should dominate inner rim")
    precondition(p.shadowOpacity <= 0.18,
                 "Avoid the black shadow from v0.3")
    count += 3
}
precondition(GlassOpticsProfile(style: .crystal).nativeBlurOpacity == 0,
             "Crystal must be genuinely transparent, without native blur")
precondition(GlassOpticsProfile(style: .balanced).nativeBlurOpacity < 0.35,
             "Balanced should keep the environment visible")
precondition(GlassOpticsProfile(style: .frosted).nativeBlurOpacity > 0.7,
             "Frosted deliberately uses stronger Sequoia blur")
count += 3
print("PASS: \(count) optical profile checks")
