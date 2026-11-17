# SequoiaGlassKit v2.1.0 — SDK preview

This is a proposed **developer SDK preview**, not a published GitHub release or a verified LaunchMe patch.

## Release objective
Make the visually approved v2.0.1 Crystal effect straightforward to integrate into independent AppKit and SwiftUI applications while preserving the exact approved renderer and optical profile.

## Added in this preview
- `GlassSurfaceConfiguration`: shared optical settings for both UI frameworks.
- `SystemGlassSurfaceView(frame:configuration:)` and `configure(with:)` for native AppKit integration.
- `SequoiaGlassPanel` and `.sequoiaGlass(configuration:)` for concise SwiftUI integration.
- An SDK-specific API reference and illustrative AppKit/SwiftUI/host-owned-Metal samples.
- SwiftPM XCTest coverage, a pinned Crystal visual-source baseline and GitHub Actions checks on `macos-15-intel` and `macos-15`.

## Verified scope
- The user explicitly approved the appearance of v2.0.1 on the Intel Mac.
- The underlying `SystemGlassSurfaceView.swift` and `GlassOpticsProfile.swift` are preserved **byte-for-byte** from the approved package and guarded by SHA-256.
- Static checks and numerical checks may be executed on Linux; **this does not validate that the new macOS-specific API compiles, links, runs or looks correct**.

## Before a public SDK release
1. Execute `bash Verification/check_release.sh` on macOS with Xcode Command Line Tools and record the result.
2. Launch `swift run GlassNativeLab` and confirm crystal/reflections/search/accessibility visually.
3. Compile an independent host app using both `SequoiaGlassPanel` and the AppKit configuration initializer; test pointer/button input.
4. Verify that both GitHub Actions jobs complete after the repository is published.
5. Check license, security/privacy, local paths, ownership and release tag before pushing.

No performance or compatibility claim is made beyond the specifically verified scope. Do not infer acceptance from Apple or LaunchMe.
