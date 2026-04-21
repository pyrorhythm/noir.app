import Foundation
import AppKit
import IOKit

enum MediaKeyAction: Equatable {
    case volume(Double)
    case brightness(Double)
}

final class MediaKeyMonitor {
    private var eventTap: CFMachPort?
    private var localMonitor: Any?
    private var globalMonitor: Any?

    var onVolumeChange: ((Double) -> Void)?
    var onBrightnessChange: ((Double) -> Void)?

    func start() {
        guard localMonitor == nil, globalMonitor == nil else { return }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .systemDefined) { [weak self] event in
            self?.handle(event)
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .systemDefined) { [weak self] event in
            self?.handle(event)
        }
    }

    func stop() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
    }

    private func handle(_ event: NSEvent) {
        guard event.type == .systemDefined,
              event.subtype.rawValue == 8
        else { return }

        let keyCode = Int32((event.data1 & 0xFFFF0000) >> 16)
        let keyState = Int((event.data1 & 0x0000FF00) >> 8)
        switch Self.action(forKeyCode: keyCode, keyState: keyState) {
        case .volume(let delta):
            onVolumeChange?(delta)
        case .brightness(let delta):
            onBrightnessChange?(delta)
        case nil:
            break
        }
    }

    static func action(forKeyCode keyCode: Int32, keyState: Int) -> MediaKeyAction? {
        guard keyState == 0xA else { return nil }

        switch keyCode {
        case NX_KEYTYPE_SOUND_UP:
            return .volume(1)
        case NX_KEYTYPE_SOUND_DOWN:
            return .volume(-1)
        case NX_KEYTYPE_MUTE:
            return .volume(0)
        case NX_KEYTYPE_BRIGHTNESS_UP:
            return .brightness(1)
        case NX_KEYTYPE_BRIGHTNESS_DOWN:
            return .brightness(-1)
        default:
            return nil
        }
    }
}
