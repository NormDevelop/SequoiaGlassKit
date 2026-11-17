# Contributing

This is an independent open-source compatibility experiment for app-owned controls on macOS 13+.

## Before a pull request
1. Run `bash Verification/check_release.sh` on macOS (Intel testing is especially valuable).
2. Keep `SystemGlassSurfaceView.swift` and `GlassOpticsProfile.swift` byte-identical to the approved baseline unless there is explicit visual change approval. `Verification/renderer_baseline.py` guards this.
3. Check Crystal on bright, dark and strongly colored backgrounds, while dragging the window.
4. Verify the accessibility fallback with **Reduce transparency** enabled.
5. Do not introduce screen-capture, private APIs, background timers or continuous GPU loops in the default library.
6. Report test OS, Mac model, observed issues and conditions; do not upload unredacted desktop screenshots.

Changes to the optional `SequoiaGlassMetal` target must not make the default `SequoiaGlassKit` target depend on Metal.

The MIT license applies. Do not submit Apple proprietary assets, code or copied WWDC media.
