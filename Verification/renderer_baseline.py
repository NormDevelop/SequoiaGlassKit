#!/usr/bin/env python3
"""Detect accidental edits to the user-approved Crystal implementation.

The SHA-256 baselines pin v2.0.1's visual renderer and profile, not its
SwiftUI adapter or the new additive public SDK API. If changing the look is
explicitly approved, review the diff and intentionally update these hashes.
"""
from hashlib import sha256
from pathlib import Path

expected = {
    'Sources/SequoiaGlassKit/SystemGlassSurfaceView.swift': '852410646ad73226ff1b9ecadf90bb67ef59926bfd434d4cb5c012858d7e2c8b',
    'Sources/SequoiaGlassKit/GlassOpticsProfile.swift': '09bee283883e8d199c0bdb716c21b52ae861cb90d796f8884aad85b5964b274f',
}

for filename, digest in expected.items():
    actual = sha256(Path(filename).read_bytes()).hexdigest()
    if actual != digest:
        raise SystemExit(f'FAIL: approved Crystal baseline changed: {filename}\n'
                         'Review the visual diff and update only with explicit approval.')
print('PASS: approved v2.0.1 Crystal renderer and optics remain byte-identical')
