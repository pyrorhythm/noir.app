import SwiftUI

struct MenuBarView: View {
    @Environment(BarManager.self) var barManager
    @Environment(WindowManagerDetector.self) var wmDetector
    @Environment(\.openSettings) private var openSettings

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

                connectionStatus

                VStack(spacing: 8) {
                    Button {
                        NSApp.activate(ignoringOtherApps: true)
                        openSettings()
                    } label: {
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

    private var connectionStatus: some View {
        HStack {
            Image(systemName: wmDetector.connectionState == .connected ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(wmDetector.connectionState == .connected ? .green : .secondary)
            Text(wmDetector.detectedWM?.name ?? "No window manager")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

#Preview("Menu Bar Extra") {
    NoirPreviewEnvironment().inject(
        into: MenuBarView()
            .padding()
    )
}

#Preview("Menu Bar Extra Editing") {
    NoirPreviewEnvironment(isEditing: true).inject(
        into: MenuBarView()
            .padding()
    )
}
