# Intel / Sequoia test record

## Source of evidence
User-supplied screenshots and short screen recordings from **MacBook Pro 2018 (Intel), macOS Sequoia 15.8**, covering iterations v0.1–v2.0, plus explicit user confirmation of v2.0.1 appearance. This file does not include the recordings or private desktop screenshots.

| Scope | What was observed | Boundary |
|---|---|---|
| Native v2.0 Crystal | Demo opened and was moved over wallpaper/Finder; visibly clearer than earlier dark blur | Tested by user; no pixel-identical Apple match claimed |
| v1.9 no-capture | Mac-native build and launch succeeded after fixing a MainActor initializer | v1.9 had an overly dark translucent appearance |
| v1.6.1 live-capture test | Approximately 43–54 displayed FPS in selected video frames | Different architecture; **not** a v2.0 performance result |
| v1.0 host-owned Metal demo | Roughly 60 FPS in sampled video readouts | Not a benchmark of another app or v2.0 |
| v2.0.1 approved source | User confirmed the v2.0.1 appearance was perfect on their Intel Mac (2026-11-17) | The conversation confirms visual satisfaction, not an independently preserved `swift build` log or CPU measurement |
| v2.1.0 SDK preview (this package) | Approved Crystal renderer and optics remain byte-identical | New public API, XCTest tests and CI workflow still require a native macOS build and separate host-app test |

## Required for a public v2.1.0 SDK preview release
- [ ] `bash Verification/check_release.sh` succeeds on the Intel Mac, including `swift test`.
- [ ] The new AppKit and SwiftUI APIs compile inside a separate host application.
- [ ] GlassNativeLab starts without Xcode installation or developer entitlements.
- [ ] Crystal remains clear over bright wallpaper and dark Finder, while dragging.
- [ ] Search text and placeholder remain readable over both backgrounds; verify the native rounded-bezel rendering against its opaque backing.
- [ ] Reflections toggle visibly changes the rim, and buttons work.
- [ ] macOS **Reduce transparency** yields a readable fallback.
- [ ] Measure actual app CPU, RAM, and energy usage in Activity Monitor; attach results only if measured.

A successful no-capture design does not automatically imply low measured energy use. No specific CPU/RAM/performance numbers are promised.
