from pathlib import Path
sdk = Path('Sources/SequoiaGlassKit')
metal = Path('Sources/SequoiaGlassMetal')
demo = Path('Sources/GlassNativeLab/main.swift').read_text()
manifest = Path('Package.swift').read_text()
assert sdk.exists() and metal.exists()
for p in (sdk, metal, Path('Sources/GlassNativeLab')):
    for file in p.glob('*.swift'):
        s = file.read_text()
        assert 'import ScreenCaptureKit' not in s, file
        assert 'SCScreenshotManager' not in s, file
        assert 'SCStream(' not in s, file
        assert 'SCShareableContent' not in s, file
assert 'ScreenCaptureKit' not in manifest
assert 'CoreVideo' not in manifest
assert 'Live starten' not in demo
assert 'MTKView' not in demo and 'import Metal' not in demo
assert 'NSVisualEffectView' in (sdk/'SystemGlassSurfaceView.swift').read_text()
assert 'SequoiaGlassMetal' in manifest and 'SequoiaGlassKit' in manifest
assert 'isPaused = true' in (metal/'SynchronizedGlassView.swift').read_text()
assert 'guard let encodeContent = encodeContent' in (metal/'SynchronizedGlassView.swift').read_text()
print('PASS: zero capture APIs; native default; GPU only host-owned and on-demand')

# Lightweight developer preview: exactly one native demo, no tracking or polling.
assert demo.count('SystemGlassSurfaceView(frame: .zero)') == 1
assert 'GlassReadableSearchField.apply' in demo
assert 'searchWell.addSubview(search)' in demo
assert 'Timer.scheduledTimer' not in demo
assert 'NSWorkspace.shared.open' in demo
print('PASS: single glass demo, accessible search and no background polling')
