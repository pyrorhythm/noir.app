import SwiftUI

@Observable
final class NotchManager {
    private(set) var activePresenter: (any NotchPresentable)?
    private(set) var isExpanded: Bool = false
    private var dismissTask: Task<Void, Never>?

    let hasNotch: Bool

    init(hasNotch: Bool) {
        self.hasNotch = hasNotch
    }

    func request(_ widget: some NotchPresentable, value: Double = 0, icon: String? = nil) {
        if let current = activePresenter,
           widget.notchPriority >= current.notchPriority {
            dismissCurrent()
        }

        activePresenter = widget
        withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
            isExpanded = true
        }

        scheduleDismiss(after: widget.notchDuration)
    }

    func dismiss(from widget: some NotchPresentable) {
        guard let active = activePresenter, active.id == widget.id else { return }
        dismissCurrent()
    }

    private func dismissCurrent() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.3)) {
            isExpanded = false
            activePresenter = nil
        }
    }

    private func scheduleDismiss(after interval: TimeInterval) {
        guard interval > 0 else { return }
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(interval))
            self.dismissCurrent()
        }
    }
}
