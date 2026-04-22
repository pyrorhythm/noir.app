import SwiftUI
import Combine

struct ClockWidget: NoirWidget {
    let id = UUID()
    var displayName: String { "Clock" }
    var systemImage: String { "clock" }
    var defaultSize: WidgetSize { .medium }
    var popover: AnyView? {
        AnyView(ClockPopoverView(date: now))
    }

    @State private var now = Date.now
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(now, format: .dateTime.hour().minute())
            .font(.system(size:12,  weight: .medium, design: .rounded))
            .foregroundStyle(.primary)
            .onReceive(timer) { time in
                now = time
            }
    }
}

private struct ClockPopoverView: View {
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                .font(.headline)
            Text(date, format: .dateTime.hour().minute().second())
                .font(.system(size:24 , weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .padding(14)
        .frame(width: 240, alignment: .leading)
    }
}
