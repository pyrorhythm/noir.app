// noirTests/Managers/NotchManagerTests.swift
import Foundation
import SwiftUI
import Testing
@testable import noir

struct MockNotchWidget: NotchPresentable {
    let id = UUID()
    var displayName: String { "MockNotch" }
    var systemImage: String { "speaker.wave.2" }
    var defaultSize: WidgetSize { .small }
    var notchPriority: NotchPriority
    var notchDuration: TimeInterval

    init(priority: NotchPriority = .normal, duration: TimeInterval = 2.0) {
        self.notchPriority = priority
        self.notchDuration = duration
    }

    var body: some View {
        Text("Mock")
    }

    var notchContent: some View {
        Text("Notch Content")
    }
}

@Suite("NotchManager")
struct NotchManagerTests {
    @Test("Initial state is not expanded")
    func initialState() {
        let manager = NotchManager(hasNotch: true)
        #expect(manager.isExpanded == false)
        #expect(manager.activePresenter == nil)
    }

    @Test("Request expands the notch")
    func requestExpands() async {
        let manager = NotchManager(hasNotch: true)
        let widget = MockNotchWidget(priority: .high, duration: 2.0)
        manager.request(widget)

        #expect(manager.isExpanded == true)
        #expect(manager.activePresenter != nil)
    }

    @Test("Higher priority preempts current presenter")
    func higherPriorityPreempts() async {
        let manager = NotchManager(hasNotch: true)
        let lowWidget = MockNotchWidget(priority: .low, duration: 5.0)
        let highWidget = MockNotchWidget(priority: .high, duration: 2.0)

        manager.request(lowWidget)
        #expect(manager.activePresenter?.displayName == "MockNotch")

        manager.request(highWidget)
        #expect(manager.isExpanded == true)
    }

    @Test("Dismiss from widget collapses the notch")
    func dismissFromWidget() async {
        let manager = NotchManager(hasNotch: true)
        let widget = MockNotchWidget(priority: .normal, duration: 0)
        manager.request(widget)
        #expect(manager.isExpanded == true)

        manager.dismiss(from: widget)
        #expect(manager.isExpanded == false)
        #expect(manager.activePresenter == nil)
    }

    @Test("Dismiss from wrong widget does nothing")
    func dismissFromWrongWidget() async {
        let manager = NotchManager(hasNotch: true)
        let widget1 = MockNotchWidget(priority: .normal, duration: 0)
        let widget2 = MockNotchWidget(priority: .normal, duration: 0)

        manager.request(widget1)
        manager.dismiss(from: widget2)
        #expect(manager.isExpanded == true)
    }

    @Test("Auto-dismiss after duration")
    func autoDismiss() async {
        let manager = NotchManager(hasNotch: true)
        let widget = MockNotchWidget(priority: .normal, duration: 0.1)
        manager.request(widget)
        #expect(manager.isExpanded == true)

        try? await Task.sleep(for: .milliseconds(200))
        #expect(manager.isExpanded == false)
    }
}
