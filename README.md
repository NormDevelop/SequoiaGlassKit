# SequoiaGlassKit

**Capture-free crystal-style controls for app-owned macOS interfaces.** An unofficial, MIT-licensed Swift Package with a native AppKit/SwiftUI module and an optional Metal module for *host-owned* GPU pixels.

**Current source:** `v2.1.0-sdk-preview` · **Requirements:** macOS 13+, Swift tools 5.9+ · **Design baseline:** v2.0.1 Crystal, visually approved on a 2018 Intel MacBook Pro running macOS Sequoia 15.8.

> **Validation status:** The v2.0.1 appearance was approved by the user on their Intel Mac. The *new* v2.1.0 SDK API, macOS unit-test target and CI workflow have not yet completed native macOS validation. Syntax/static checks on non-macOS machines are not a substitute for that test. This project does **not** implement Apple's proprietary Liquid Glass renderer and does not modify Finder, Dock, or the menu bar.

## What you get

| `SequoiaGlassKit` — default | `SequoiaGlassMetal` — optional |
|---|---|
| AppKit & SwiftUI glass surfaces | Same-frame optical refraction of host-owned Metal content |
| Crystal, Balanced, Frosted | A host-supplied Metal render encoder callback |
| No screen capture or screen recording permission | No capture of other apps or system pixels |
| No background polling or GPU display loop | Event-driven rendering by default |
| Shared `GlassSurfaceConfiguration` | Separate product; never required for the native material |

## Install

In Xcode choose **File → Add Package Dependencies…** and select the checked-out local package folder. After the repository is published, add its *actual* Git URL and select the `SequoiaGlassKit` library product for your app target. No external packages are required.

**AppKit**

```swift
import AppKit
import SequoiaGlassKit

let glass = SystemGlassSurfaceView(
    frame: NSRect(x: 0, y: 0, width: 360, height: 88),
    configuration: GlassSurfaceConfiguration(
        cornerRadius: 28, opticalStyle: .crystal))
parentView.addSubview(glass)
glass.contentView.addSubview(existingButton)
```

For window-level transparency the host sets `window.isOpaque = false` and `window.backgroundColor = .clear`. For automatic layout, constrain the glass to its host. An existing `SystemGlassSurfaceView(frame:)` integration remains valid.

**SwiftUI**

```swift
import SwiftUI
import SequoiaGlassKit

SequoiaGlassPanel {
    HStack {
        Text("My app")
        Button("Open") { openItem() }
    }
}
```

For existing controls, the earlier `Button("…") { … }.padding(14).sequoiaGlass(cornerRadius: 24)` modifier still works. New call sites can use `.sequoiaGlass(configuration: GlassSurfaceConfiguration(...))` so AppKit and SwiftUI share options.

See [API reference](Docs/API_REFERENCE.md), [integration guide](Docs/INTEGRATION.md), [AppKit sample](Examples/AppKitMinimal.swift), [SwiftUI sample](Examples/SwiftUIMinimal.swift), [Metal sample](Examples/MetalOwnedPixels.swift), or [German quickstart](Docs/DE_QUICKSTART.md).

## Try the demo / verify

```bash
cd SequoiaGlassKit_v2.1.0_SDK_Preview
bash Verification/check_release.sh
swift run GlassNativeLab
```

Run the last command **on a Mac**. The demo is a single Crystal panel with native search, style selector, reflection switch and Finder button. Check it over bright and dark backgrounds and with **Reduce transparency** enabled.

The verification script checks Swift syntax, package manifest, capture/privacy policy, **byte-identical Crystal renderer baseline**, deterministic geometry/timing/optics/contrast checks, plus native build and XCTest tests **when running on macOS**. GitHub Actions targets both Apple Silicon macOS 15 and Intel macOS 15 runners. A successful CI build is not a substitute for manually viewing the demo on the intended Mac.

## Important limitations

- Crystal draws a transparent optical edge: it does **not** bend another app's or the wallpaper's pixels. Balanced/Frosted add native blur. Optional Metal can refract only textures supplied by the host app.
- This kit does not operate as a system-wide UI patch, doesn't need ScreenCaptureKit, and doesn't claim proprietary Apple rendering compatibility.
- **LaunchMe integration has not been implemented or confirmed.** The package is offered as a possible optional contribution after integration testing; there is no promise its developers will accept it.
- No calibrated CPU, memory, power or GPU benchmark is claimed for v2.1.0.

## Open source / publishing

Independent community experiment; not affiliated with Apple or LaunchMe. No proprietary Apple assets or code, no included user recordings, and no telemetry or network dependency. MIT licensed: [LICENSE](LICENSE). See [changelog](CHANGELOG.md), [release checklist](Docs/GITHUB_RELEASE_CHECKLIST.md), [Intel test record](Docs/INTEL_TEST_REPORT.md), and [contribution guide](CONTRIBUTING.md).
