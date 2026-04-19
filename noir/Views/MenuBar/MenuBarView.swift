import SwiftUI

struct MenuBarView: View {
    @Environment(BarManager.self) var barManager
    @Environment(SettingsStore.self) var settings
    @Environment(WindowManagerDetector.self) var wmDetector

    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.title2)
                    Text("Noir")
                        .font(.headline)
                    Spacer()
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text("v\(version)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                VStack(spacing: 8) {
                    SettingsLink {
                        Label("Open Settings", systemImage: "gear")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        barManager.isEditing.toggle()
                    } label: {
                        Label(barManager.isEditing ? "Done Editing" : "Toggle Edit Mode", systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                    
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Label("Quit Noir", systemImage: "power")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .frame(width: 280)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
