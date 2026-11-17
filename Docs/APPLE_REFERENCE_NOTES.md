# Visual reference and provenance

Official Apple references:
- https://developer.apple.com/videos/play/wwdc2025/219/ — WWDC25 Meet Liquid Glass (light concentration, refraction, adaptive material and motion)
- https://developer.apple.com/design/human-interface-guidelines/materials — controls and navigation hierarchy
- https://developer.apple.com/documentation/appkit/nsvisualeffectview — native translucency/vibrancy on older macOS versions

SequoiaGlassKit uses these principles as **design references**, not as copied Apple code or assets. No Apple logos, design screenshots, video frames or copyrighted images are included in the repository.

Visual quality decisions carried forward from the v2.0 Intel test:
- Keep the completely transparent Crystal center (no brown system-material overlay).
- Use event-driven directional edge glints; no timer.
- Keep the optically suggestive boundary separate from real refraction on host-owned Metal textures.
- Keep text readable by styling **content controls** rather than dimming the whole glass panel.

No quantitative, pixel-accurate comparison to Apple's proprietary renderer has been verified. Real Sequoia Desktop pixel refraction is explicitly out of scope without image capture.
