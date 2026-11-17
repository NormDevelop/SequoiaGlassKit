# SequoiaGlassKit — Entwickler-Schnellstart (Deutsch)

Die freigegebene **Crystal-Optik aus v2.0.1** bleibt unverändert. Das SDK wird als Swift Package in bestehende macOS-Apps eingebaut. Es ersetzt keine Systemoberflächen und benötigt keine Bildschirmaufnahme.

## Auf dem Intel-Mac überprüfen

```bash
cd ~/Downloads/SequoiaGlassKit_v2.1.0_SDK_Preview
bash Verification/check_release.sh
swift run GlassNativeLab
```

Der erste Befehl prüft Swift-Syntax, Abhängigkeiten, Datenschutz, den unveränderten Glaseffekt und (auf dem Mac) den nativen Build und die XCTest-Tests. Der zweite startet die bekannte Demo.

## Einbau in einer eigenen App

In Xcode: **File → Add Package Dependencies …**. Für den lokalen Test den entpackten Ordner auswählen. Nach Veröffentlichung kann die tatsächliche GitHub-Repository-URL eingetragen werden. Der App das Produkt **SequoiaGlassKit** hinzufügen, nicht automatisch das optionale Metal-Modul.

**AppKit:**

```swift
import SequoiaGlassKit

let glass = SystemGlassSurfaceView(
    frame: .zero,
    configuration: GlassSurfaceConfiguration(cornerRadius: 28)
)
parentView.addSubview(glass)
glass.contentView.addSubview(existingButton)
```

**SwiftUI:**

```swift
import SequoiaGlassKit

SequoiaGlassPanel {
    Button("Öffnen") { openSomething() }
}
```

Die vollständige technische Beschreibung findest du in `Docs/API_REFERENCE.md` und `Docs/INTEGRATION.md`.

## Vor einer öffentlichen Veröffentlichung

- Auf dem Intel Mac Build, Tests und Demo wiederholen.
- Die Komponente in einer **zweiten, bestehenden App** einsetzen und die Reaktion echter AppKit-/SwiftUI-Controls prüfen.
- GitHub-Workflow mit `macos-15-intel` erfolgreich ausführen lassen.
- Erst danach einen Versions-Tag und einen Link für den LaunchMe-Entwickler veröffentlichen.

Dies ist eine unabhängige MIT-lizenzierte Community-Komponente, kein Apple-Produkt und keine bestätigte LaunchMe-Integration.
