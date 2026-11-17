# LaunchMe handoff — technical contribution proposal

## What we can offer
An MIT-licensed Swift Package whose Crystal appearance was user-approved in v2.0.1 on a 2018 Intel MacBook Pro with macOS Sequoia 15.8. The new v2.1.0 integration API is not yet Mac-build verified. It provides a capture-free, native AppKit/SwiftUI surface with directional highlights, a no-blur Crystal mode and accessible controls. A separate optional Metal renderer can refract **LaunchMe-owned source textures**.

## What it is not
It is not Apple's proprietary Liquid Glass, does not replace the OS menu bar, Finder, Dock, or other applications' controls, and does not bend desktop pixels when no background texture is available. The kit does not contain or copy LaunchMe source code and has **not** been integrated into LaunchMe.

## Recommended evaluation path
1. Review `README.md`, `Docs/API_REFERENCE.md`, `Docs/INTEGRATION.md`, `LICENSE`.
2. Build and test the exact SDK preview on Intel macOS and in an independent host app before contacting any third-party developer.
3. Add only `SequoiaGlassKit` SwiftPM product to a test app; create a clear window surface and insert existing native controls.
4. Use the optional `SequoiaGlassMetal` only if LaunchMe already owns renderable source textures; don't turn on a GPU animation loop for static material.
5. Run accessibility tests and compare Clear/Balanced/Frosted over light/dark wallpapers.
6. Validate real CPU/RAM/energy on the target Mac before any performance claims.

## Intel evidence and known limitations
See `Docs/INTEL_TEST_REPORT.md`; the user subsequently approved v2.0.1 visually. The new SDK APIs and v2.1.0 CI tests need native macOS validation before any external handoff. Repo intentionally excludes personal screenshots and any user recordings.

The user plans to contact the LaunchMe developer **only after the final updated version passes on their Intel Mac**. No promises of free access, beta status, or developer acceptance should be inferred.
