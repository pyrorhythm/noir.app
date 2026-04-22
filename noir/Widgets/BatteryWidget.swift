import IOKit.ps
import SwiftUI

struct BatteryWidget: NoirWidget {
    let id = UUID()
    var displayName: String { "Battery" }
    var systemImage: String { "battery.75percent" }
    var defaultSize: WidgetSize { .small }

    var body: some View {
        BatteryWidgetView()
    }
}

private struct BatteryWidgetView: View {
    @State private var battery = BatterySnapshot.current

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: battery.systemImage)
            Text("\(battery.percent)%")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .monospacedDigit()
        }
        .task {
            while !Task.isCancelled {
                battery = BatterySnapshot.current
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }
}

private struct BatterySnapshot: Equatable {
    let percent: Int
    let isCharging: Bool

    var systemImage: String {
        if isCharging { return "battery.100percent.bolt" }
        switch percent {
        case 90...100: return "battery.100percent"
        case 60..<90: return "battery.75percent"
        case 35..<60: return "battery.50percent"
        case 15..<35: return "battery.25percent"
        default: return "battery.0percent"
        }
    }

    static var current: BatterySnapshot {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(info).takeRetainedValue() as NSArray

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source as CFTypeRef)
                .takeUnretainedValue() as? [String: Any]
            else { continue }

            let percent = description[kIOPSCurrentCapacityKey] as? Int ?? 0
            let state = description[kIOPSPowerSourceStateKey] as? String
            return BatterySnapshot(percent: percent, isCharging: state == kIOPSACPowerValue)
        }

        return BatterySnapshot(percent: 100, isCharging: false)
    }
}
