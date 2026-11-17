// Illustrative SwiftUI snippet for an existing application view.
import SwiftUI
import SequoiaGlassKit

struct ExampleGlassControl: View {
    var body: some View {
        SequoiaGlassPanel(configuration: GlassSurfaceConfiguration(
            cornerRadius: 28, opticalStyle: .crystal)) {
            HStack {
                Text("LaunchMe")
                Button("Open") { /* host app action */ }
            }
        }
    }
}

// Existing call sites also keep working:
// Button("Open") { ... }.padding(14).sequoiaGlass(cornerRadius: 24)
