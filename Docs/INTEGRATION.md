# Integration guide for an existing macOS application

## Choose the right target
- `SequoiaGlassKit` — native AppKit/SwiftUI optical styling; no capture permission, Metal requirement, always-on service or timer.
- `SequoiaGlassMetal` — optional Metal shader for pixels already provided by the host app. **It does not read Finder or the desktop.**

## Swift Package Manager
In Xcode: **File → Add Package Dependencies…** and choose the Git repository URL once you have uploaded it. For a local integration, point Xcode to the package directory. Add product `SequoiaGlassKit` to the app target. Do not add `SequoiaGlassMetal` unless the app supplies an `MTLTexture` or encodes its own GPU content.

## Unified configuration (new in the SDK preview)

The new `GlassSurfaceConfiguration` lets both AppKit and SwiftUI use the same styling settings. `SystemGlassSurfaceView(frame:configuration:)` applies those settings without modifying the Crystal renderer:

```swift
let options = GlassSurfaceConfiguration(cornerRadius: 28,
                                        opticalStyle: .crystal)
let glass = SystemGlassSurfaceView(frame: .zero, configuration: options)
parentView.addSubview(glass)
glass.contentView.addSubview(existingButton)
```

To update the settings later without losing the button: `glass.configure(with: options)`. For SwiftUI, wrap controls in `SequoiaGlassPanel { ... }` or attach `.sequoiaGlass(configuration: options)` to existing views. Previous initializers and modifiers continue to work. See `Docs/API_REFERENCE.md`.

## AppKit example
See `Examples/AppKitMinimal.swift`. A crystal surface requires an NSWindow/window background that permits transparency:

```swift
window.isOpaque = false
window.backgroundColor = .clear
```

Create a `SystemGlassSurfaceView`, set `.opticalStyle = .crystal`, and add native controls to `glass.contentView`. The small capsule border and directional highlights are automatically rendered. The native blur variants `.balanced` and `.frosted` remain available.

For an existing `NSSearchField`, use the reusable contrast-safe style:

```swift
GlassReadableSearchField.apply(to: search, placeholder: "Search")
glass.contentView.addSubview(search)
```

The search field is intentionally light and opaque; this preserves readability over unpredictable desktop colors. **AppKit note:** native rounded fields can ignore `backgroundColor`, so give the field a small opaque, rounded `NSView` backing when integrating over highly variable backdrops. The `GlassNativeLab` demo includes this backing. It does **not** make Finder's own search field transparent or change any system app.

## SwiftUI example

```swift
SequoiaGlassPanel(configuration: .init(cornerRadius: 28)) {
    HStack { Text("My app"); Button("Open") { openItem() } }
}
```

See `Examples/SwiftUIMinimal.swift`. Use `.sequoiaGlass(cornerRadius:opticalStyle:)` on app-owned controls, not as a global window replacement.

## Metal specifics
For actual refraction, the host must provide the pixel data **it owns**. `SynchronizedGlassView` renders the host's source and composited lens within one command buffer. It is paused by default and draws on request; avoid enabling continuous animation without a user-visible reason.

## Runtime and privacy
No ScreenCaptureKit, accessibility automation, audio capture, private API, helper daemon or network permission is needed for the SDK. The sample uses `NSWorkspace` to open the user's home folder when they press Finder. macOS's "Reduce transparency" option triggers a solid fallback. 

## Limits
This is **not** the official macOS 26 Liquid Glass renderer. Transparent Crystal does not refract pixels of other apps or the wallpaper. Different apps' rendering hierarchies may require integration work, particularly when mixing layer-backed AppKit/SwiftUI/Metal.
