import Network
import SwiftUI

struct NetworkWidget: NoirWidget {
    let id = UUID()
    var displayName: String { "Network" }
    var systemImage: String { "wifi" }
    var defaultSize: WidgetSize { .small }

    var body: some View {
        NetworkWidgetView()
    }
}

private struct NetworkWidgetView: View {
    @State private var monitor = NetworkStateMonitor()

    var body: some View {
        Image(systemName: monitor.systemImage)
            .foregroundStyle(monitor.isConnected ? .primary : .secondary)
            .task {
                monitor.start()
            }
    }
}

@MainActor
@Observable
private final class NetworkStateMonitor {
    var isConnected = true
    var usesWiFi = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "dev.pyrorhythm.noir.network")
    private var didStart = false

    var systemImage: String {
        guard isConnected else { return "wifi.slash" }
        return usesWiFi ? "wifi" : "network"
    }

    func start() {
        guard !didStart else { return }
        didStart = true
        monitor.pathUpdateHandler = { [monitor = self] path in
            let isConnected = path.status == .satisfied
            let usesWiFi = path.usesInterfaceType(.wifi)
            Task { @MainActor in
                monitor.isConnected = isConnected
                monitor.usesWiFi = usesWiFi
            }
        }
        monitor.start(queue: queue)
    }
}
