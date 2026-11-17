# GitHub release checklist — v2.1.0-sdk-preview (not yet published)

## Technical acceptance
- [ ] Run `bash Verification/check_release.sh` successfully on the 2018 Intel Mac with Sequoia 15.8.
- [ ] Confirm `swift run GlassNativeLab` opens and keeps the approved Crystal appearance when dragged over light/dark backgrounds.
- [ ] Verify search input, buttons, style switch and hover/reflections do not steal focus or block user interaction.
- [ ] Verify Reduce transparency and Increase contrast accessibility settings.
- [ ] Compile and exercise a **separate host app** using both the new AppKit and SwiftUI integration APIs.
- [ ] After publication, see both CI jobs (Intel/standard macOS 15) complete successfully.
- [ ] Record device model, macOS version, Swift version, check result, date and any known limitations.

## Security, licensing and privacy
- [ ] Review the `LICENSE` and any third-party contributions before publishing.
- [ ] Inspect staged files for personal usernames, token values, secrets, private paths and hidden directories.
- [ ] Do not publish personal recordings or screenshots without explicit permission and redaction.
- [ ] Confirm capture-free behavior and no automatic polling/background processes.
- [ ] Keep branding independent of Apple and LaunchMe; no suggestion of official endorsement.

## Publish only after acceptance
- [ ] Create a public GitHub repository (suggested name: `SequoiaGlassKit`), and commit the *contents* of this package root.
- [ ] Let the repository's actual URL, not a placeholder, be the SwiftPM dependency URL.
- [ ] Add `v2.1.0-sdk-preview` as a pre-release tag only after its native/macOS validation is completed.
- [ ] Publish release notes and documented limitations; avoid claims of an existing LaunchMe integration.

Example terminal commands, **only after** creating/reviewing the remote:

```bash
git init
git add .
git commit -m "SequoiaGlassKit v2.1.0 SDK preview"
git branch -M main
# After creating your own repository and replacing YOUR_REPOSITORY_URL:
git remote add origin YOUR_REPOSITORY_URL
git push -u origin main
# Tag only once the native checks and CI are complete:
git tag v2.1.0-sdk-preview
git push origin v2.1.0-sdk-preview
```

Do not execute remote commands with a placeholder. The supplied ZIP does not itself create a GitHub repository or release.
