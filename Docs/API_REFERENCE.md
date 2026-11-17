# SDK API reference — v2.1.0 preview

**Entry point:** `import SequoiaGlassKit` · Swift 5.9+ · macOS 13+.

## Recommended: same configuration in AppKit and SwiftUI

```swift
let options = GlassSurfaceConfiguration(
    cornerRadius: 28,
    opticalStyle: .crystal,
    appearanceMode: .system,
    material: .popover,
    highlights: true
)
```

`GlassSurfaceConfiguration` is a value containing the presentation settings; it does not allocate a window or request access to screen pixels. The default is Crystal, matching the approved optical profile.

| Public API | Purpose |
|---|---|
| `GlassSurfaceConfiguration(...)` | Shared styling values for AppKit and SwiftUI |
| `SystemGlassSurfaceView(frame:configuration:)` | Creates a native view and applies options |
| `view.configure(with:)` | Changes an existing AppKit view without removing its children |
| `view.contentView` | Add the app's real AppKit buttons, text, search fields |
| `SequoiaGlassPanel(configuration:contentPadding:content:)` | SwiftUI container whose content stays ordinary SwiftUI |
| `.sequoiaGlass(configuration:)` | Add a glass background to an existing SwiftUI view |
| `.sequoiaGlass(cornerRadius:opticalStyle:...)` | Previous modifier, still supported |
| `GlassReadableSearchField.apply(to:placeholder:)` | Contrast-oriented search styling |
| `GlassOpticalStyle.crystal / .balanced / .frosted` | Transparent / subtly blurred / frosted presets |
| `GlassSurfaceAppearance.system / .light / .dark` | Appearance selection; system is preferred |

The public properties of `SystemGlassSurfaceView` remain available. Existing integrations using `SystemGlassSurfaceView(frame:)` require no migration.

### AppKit

```swift
import AppKit
import SequoiaGlassKit

let options = GlassSurfaceConfiguration(cornerRadius: 28)
let glass = SystemGlassSurfaceView(frame: .zero, configuration: options)
container.addSubview(glass)
glass.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    glass.leadingAnchor.constraint(equalTo: container.leadingAnchor),
    glass.trailingAnchor.constraint(equalTo: container.trailingAnchor),
    glass.topAnchor.constraint(equalTo: container.topAnchor),
    glass.bottomAnchor.constraint(equalTo: container.bottomAnchor)
])
glass.contentView.addSubview(existingButton)

// Existing instance, runtime style change:
var newOptions = options
newOptions.opticalStyle = .balanced
glass.configure(with: newOptions)
```

When the background should reveal the desktop, use an app-owned transparent `NSWindow` with `isOpaque = false` and `backgroundColor = .clear`. Crystal does not read or refract pixels of other applications.

### SwiftUI

```swift
import SwiftUI
import SequoiaGlassKit

SequoiaGlassPanel(configuration: GlassSurfaceConfiguration(cornerRadius: 28)) {
    HStack {
        Text("My controls")
        Button("Open") { openItem() }
    }
}

// Alternatively, attach only a background:
Text("Ready")
    .padding(12)
    .sequoiaGlass(configuration: .init(cornerRadius: 20))
```

The panel wraps content with 16 pt of padding by default. Use `contentPadding:` to override. The embedded surface is behind the content; do not put additional controls inside the background `NSViewRepresentable`.

## Optional Metal target

`import SequoiaGlassMetal` only if the host already renders its own GPU pixels. Use `SynchronizedGlassView(frame:device:)`, provide a render encoder through `encodeContent`, and call `requestContentFrame()` when scene content changes. The callback must not end the provided encoder. See `Examples/MetalOwnedPixels.swift` and the integration guide.

`SequoiaGlassMetal` does not create desktop snapshots, capture other windows or grant access to arbitrary `NSView`/SwiftUI pixels. Do not use it simply to style a standard button.

## Stability and threading

- Configure AppKit views on the main thread / main actor.
- `GlassSurfaceConfiguration` is additive; the approved renderer source and optics constants are pinned by a SHA-256 regression gate.
- Existing `SequoiaGlassSurface` and `.sequoiaGlass(...)` APIs remain supported.
- New API code is syntactically checked in this preview; **native linking and runtime integration of v2.1.0 still require the macOS CI workflow and Intel acceptance test**.
