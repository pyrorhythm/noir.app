import SwiftUI
import Combine

struct ClockWidget: NoirWidget {
    let id = UUID()
    var displayName: String { "Clock" }
    var systemImage: String { "clock" }
    var defaultSize: WidgetSize { .medium }

    @State private var now = Date.now
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(now, format: .dateTime.hour().minute())
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.primary)
            .onReceive(timer) { time in
                now = time
            }
    }
}
