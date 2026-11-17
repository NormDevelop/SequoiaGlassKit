# Changelog

## 2.1.0-sdk-preview — SDK integration work (2026-11-17)
- Adds the additive shared `GlassSurfaceConfiguration` API for AppKit and SwiftUI.
- Adds `SystemGlassSurfaceView(frame:configuration:)` and `configure(with:)` without removing existing APIs or child content.
- Adds `SequoiaGlassPanel` and `.sequoiaGlass(configuration:)` while preserving the original modifier.
- Adds AppKit, SwiftUI and host-owned Metal integration samples, an API reference and a German quickstart.
- Adds package-based XCTest API/profile/contrast tests and a GitHub Actions matrix including macOS 15 Intel.
- Pins the visually approved v2.0.1 Crystal renderer and optics source by SHA-256 to prevent accidental visual regressions.
- Does **not** change the Crystal renderer or optics values; does not add screen capture, desktop sampling, background loops or OS patches.
- **Validation pending:** native build, XCTest run, independent host-app integration and CI for this exact SDK preview.

## 2.0.1 — GitHub Developer Preview (2026-11-17)
- Preserves the visually tested v2.0 Crystal renderer; no new desktop sampling.
- Adds an accessible, light, native AppKit search-field style with verified sRGB contrast for text and placeholder.
- Replaces the two-panel calibration demo with one small glass capsule and working controls.
- Documents direct SwiftPM integration, app-owned Metal rendering, limitations and privacy.
- Adds a minimal AppKit snippet, GitHub release checklist and updated verification.
- Visual appearance subsequently approved by the user on the 2018 Intel Mac (macOS Sequoia); no independently archived build log.

## 2.0 — Crystal Edge
- Adds a true transparent Crystal material with multi-layer optical rim, Balanced and Frosted alternatives.
- Keeps optional app-owned Metal texture refraction separate from the default native module.
- Removes all screen-capture and live-start paths from the package.
