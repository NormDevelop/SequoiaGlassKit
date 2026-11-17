#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

printf '%s\n' '[1/9] Swift syntax (sources, examples, tests)'
while IFS= read -r -d '' file; do
  swiftc -frontend -parse "$file"
done < <(find Sources Examples Tests -name '*.swift' -print0)

printf '%s\n' '[2/9] Swift Package manifest'
swift package dump-package >/dev/null

printf '%s\n' '[3/9] Static privacy and dependency policy'
python3 Verification/privacy_gate.py

printf '%s\n' '[4/9] Approved Crystal appearance baseline'
python3 Verification/renderer_baseline.py

TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT
printf '%s\n' '[5/9] Standalone geometry and frame-budget checks'
cp Verification/GlassCapsuleGeometryChecks.swift "$TEMP/main.swift"
swiftc Sources/SequoiaGlassKit/GlassCapsuleGeometry.swift "$TEMP/main.swift" -o "$TEMP/capsules"
"$TEMP/capsules"
cp Verification/FrameBudgetChecks.swift "$TEMP/main.swift"
swiftc Sources/SequoiaGlassMetal/SharedFrameBudget.swift "$TEMP/main.swift" -o "$TEMP/frames"
"$TEMP/frames"

printf '%s\n' '[6/9] Optical profile regression tests'
cp Verification/GlassOpticsChecks.swift "$TEMP/main.swift"
swiftc Sources/SequoiaGlassKit/GlassOpticsProfile.swift "$TEMP/main.swift" -o "$TEMP/optics"
"$TEMP/optics"

printf '%s\n' '[7/9] Control contrast checks'
cp Verification/GlassControlContrastChecks.swift "$TEMP/main.swift"
swiftc Sources/SequoiaGlassKit/GlassControlPalette.swift "$TEMP/main.swift" -o "$TEMP/contrast"
"$TEMP/contrast"

printf '%s\n' '[8/9] Native build'
if [[ "$(uname -s)" == 'Darwin' ]]; then
  swift build
else
  echo 'NOT RUN: AppKit / Metal compilation requires macOS'
fi

printf '%s\n' '[9/9] XCTest suite'
if [[ "$(uname -s)" == 'Darwin' ]]; then
  swift test
else
  echo 'NOT RUN: AppKit / XCTest target requires macOS'
fi
printf '%s\n' 'PASS: every verification available on this system'
