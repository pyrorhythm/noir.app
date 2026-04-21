import SwiftUI

struct WMSecuritySettingsView: View {
    @Environment(WindowManagerDetector.self) var wmDetector

    var body: some View {
        Form {
            Section("Connection") {
                LabeledContent("Status") {
                    Label(statusTitle, systemImage: statusImage)
                        .foregroundStyle(statusStyle)
                }

                if let detectedWM = wmDetector.detectedWM {
                    LabeledContent("Adapter") {
                        Text(detectedWM.name)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var statusTitle: String {
        switch wmDetector.connectionState {
        case .connected: "Connected"
        case .disconnected: "Disconnected"
        case .reconnecting: "Checking"
        }
    }

    private var statusImage: String {
        switch wmDetector.connectionState {
        case .connected: "checkmark.circle"
        case .disconnected: "xmark.circle"
        case .reconnecting: "arrow.triangle.2.circlepath"
        }
    }

    private var statusStyle: Color {
        switch wmDetector.connectionState {
        case .connected: .green
        case .disconnected, .reconnecting: .secondary
        }
    }
}

#Preview("Window Manager Connected") {
    NoirPreviewEnvironment(detectedWindowManagerName: "aerospace").inject(
        into: WMSecuritySettingsView()
            .frame(width: 420, height: 240)
    )
}

#Preview("Window Manager Disconnected") {
    NoirPreviewEnvironment(detectedWindowManagerName: nil).inject(
        into: WMSecuritySettingsView()
            .frame(width: 420, height: 240)
    )
}
