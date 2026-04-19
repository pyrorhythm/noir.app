import SwiftUI

struct WMSecuritySettingsView: View {
    @Environment(SettingsStore.self) var settings
    @Environment(WindowManagerDetector.self) var wmDetector

    var body: some View {
        VStack(spacing: 16) {
            Text("Window Manager Integration")
                .font(.headline)

            if wmDetector.connectionState == .connected {
                Label("Connected: \(wmDetector.detectedWM?.name ?? "Unknown")", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
            } else {
                Label("No window manager detected", systemImage: "xmark.circle")
                    .foregroundStyle(.secondary)
            }

            Text("WM adapter configuration coming in sub-project 4")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
