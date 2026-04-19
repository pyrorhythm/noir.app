import Foundation
import AppKit

final class MediaKeyMonitor {
    private var eventTap: CFMachPort?

    var onVolumeChange: ((Double) -> Void)?
    var onBrightnessChange: ((Double) -> Void)?

    func start() {
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
    }
}
