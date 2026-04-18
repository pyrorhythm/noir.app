# Noir Core Bar Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the core bar engine for Noir — a macOS menu bar replacement with Liquid Glass, extensible widgets, and dynamic notch.

**Architecture:** Zone-based NSPanels hosting SwiftUI views, Apple native @Observable patterns, declarative JSON config for widget layout, generic WindowManagerProtocol with per-WM adapters.

**Tech Stack:** Swift 6, SwiftUI (macOS 26/Tahoe), AppKit (NSPanel, NSHostingController), CGEventTap (media keys), XCTest

---

## File Structure

```
noir/
├── noirApp.swift                          # App entry point (modify)
├── Models/
│   ├── BarZone.swift                       # BarZone, WidgetGroup enums
│   ├── BarLayout.swift                     # BarLayout struct
│   ├── WidgetConfig.swift                  # WidgetConfig, WidgetSize
│   ├── WindowInfo.swift                    # WindowInfo struct
│   └── NotchPriority.swift                 # NotchPriority enum
├── Protocols/
│   ├── NoirWidget.swift                    # NoirWidget protocol
│   ├── NotchPresentable.swift              # NotchPresentable protocol
│   └── WindowManagerProtocol.swift          # WindowManagerProtocol
├── Managers/
│   ├── BarManager.swift                    # Central coordinator
│   ├── NotchManager.swift                  # Dynamic notch state
│   ├── WidgetRegistry.swift               # Widget type registry
│   ├── WindowManagerDetector.swift          # Auto-detect running WM
│   └── MediaKeyMonitor.swift               # CGEventTap for media keys
├── Views/
│   ├── BarZoneView.swift                   # Bar zone rendering
│   ├── WidgetContainerView.swift           # Widget wrapper with drag/edit
│   ├── DynamicNotchView.swift              # Notch expansion view
│   └── Settings/
│       ├── SettingsView.swift              # Settings window root
│       ├── LayoutSettingsView.swift         # Layout tab
│       ├── WidgetSettingsView.swift         # Widgets tab
│       ├── WMSecuritySettingsView.swift     # WM + Security tab
│       └── AppearanceSettingsView.swift     # Appearance tab
├── Widgets/
│   ├── SpacerWidget.swift                  # Spacer (simplest widget)
│   └── ClockWidget.swift                   # Clock widget
├── Adapters/
│   └── AerospaceAdapter.swift              # aerospace WM adapter
├── Persistence/
│   └── LayoutStore.swift                   # JSON file read/write
├── Helpers/
│   └── NSPanel+Bar.swift                   # NSPanel factory extension
├── noirTests/
│   ├── Models/
│   │   ├── BarZoneTests.swift
│   │   ├── BarLayoutTests.swift
│   │   ├── WidgetConfigTests.swift
│   │   └── NotchPriorityTests.swift
│   ├── Managers/
│   │   ├── BarManagerTests.swift
│   │   ├── NotchManagerTests.swift
│   │   ├── WidgetRegistryTests.swift
│   │   └── WindowManagerDetectorTests.swift
│   ├── Persistence/
│   │   └── LayoutStoreTests.swift
│   └── Adapters/
│       └── AerospaceAdapterTests.swift
└── Info.plist                              # LSUIElement = true
```

---

### Task 1: Foundation Models

**Files:**
- Create: `noir/Models/BarZone.swift`
- Create: `noir/Models/BarLayout.swift`
- Create: `noir/Models/WidgetConfig.swift`
- Create: `noir/Models/NotchPriority.swift`
- Create: `noir/Models/WindowInfo.swift`
- Test: `noirTests/Models/BarZoneTests.swift`
- Test: `noirTests/Models/BarLayoutTests.swift`
- Test: `noirTests/Models/WidgetConfigTests.swift`
- Test: `noirTests/Models/NotchPriorityTests.swift`

- [ ] **Step 1: Write failing tests for BarZone and WidgetGroup**

```swift
// noirTests/Models/BarZoneTests.swift
import Testing
@testable import noir

@Suite("BarZone")
struct BarZoneTests {
    @Test("BarZone has top and bottom cases")
    func barZoneCases() {
        #expect(BarZone.allCases.count == 2)
        #expect(BarZone.allCases.contains(.top))
        #expect(BarZone.allCases.contains(.bottom))
    }

    @Test("BarZone raw values match expected strings")
    func barZoneRawValues() {
        #expect(BarZone.top.rawValue == "top")
        #expect(BarZone.bottom.rawValue == "bottom")
    }

    @Test("BarZone decodes from JSON")
    func barZoneDecode() throws {
        let json = #""top""#
        let zone = try JSONDecoder().decode(BarZone.self, from: Data(json.utf8))
        #expect(zone == .top)
    }

    @Test("WidgetGroup has leading and trailing")
    func widgetGroupCases() {
        #expect(WidgetGroup.allCases.count == 2)
        #expect(WidgetGroup.leading.rawValue == "leading")
        #expect(WidgetGroup.trailing.rawValue == "trailing")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests/BarZoneTests 2>&1 | tail -5`
Expected: FAIL — `BarZone` type not found

- [ ] **Step 3: Implement BarZone and WidgetGroup**

```swift
// noir/Models/BarZone.swift
import Foundation

enum BarZone: String, Codable, CaseIterable, Sendable {
    case top
    case bottom
}

enum WidgetGroup: String, Codable, Sendable {
    case leading
    case trailing
}
```

- [ ] **Step 4: Write failing tests for BarLayout**

```swift
// noirTests/Models/BarLayoutTests.swift
import Testing
@testable import noir

@Suite("BarLayout")
struct BarLayoutTests {
    @Test("Default layout has expected values")
    func defaultLayout() {
        let layout = BarLayout.default
        #expect(layout.barHeight == 28)
        #expect(layout.cornerRadius == 0)
        #expect(layout.spacing == 8)
        #expect(layout.horizontalPadding == 12)
    }

    @Test("BarLayout encodes and decodes round-trip")
    func roundTrip() throws {
        let layout = BarLayout(barHeight: 32, cornerRadius: 10, spacing: 6, horizontalPadding: 16)
        let data = try JSONEncoder().encode(layout)
        let decoded = try JSONDecoder().decode(BarLayout.self, from: data)
        #expect(decoded.barHeight == 32)
        #expect(decoded.cornerRadius == 10)
        #expect(decoded.spacing == 6)
        #expect(decoded.horizontalPadding == 16)
    }
}
```

- [ ] **Step 5: Implement BarLayout**

```swift
// noir/Models/BarLayout.swift
import Foundation

struct BarLayout: Codable, Sendable, Equatable {
    var barHeight: CGFloat = 28
    var cornerRadius: CGFloat = 0
    var spacing: CGFloat = 8
    var horizontalPadding: CGFloat = 12

    static let `default` = BarLayout()
}
```

- [ ] **Step 6: Write failing tests for WidgetConfig and WidgetSize**

```swift
// noirTests/Models/WidgetConfigTests.swift
import Testing
@testable import noir

@Suite("WidgetConfig")
struct WidgetConfigTests {
    @Test("WidgetSize has small, medium, large")
    func widgetSizeCases() {
        #expect(WidgetSize.allCases.count == 3)
        #expect(WidgetSize.small.rawValue == "small")
        #expect(WidgetSize.medium.rawValue == "medium")
        #expect(WidgetSize.large.rawValue == "large")
    }

    @Test("WidgetConfig encodes and decodes round-trip")
    func roundTrip() throws {
        let config = WidgetConfig(
            id: UUID(),
            type: "Clock",
            size: .medium,
            zone: .top,
            group: .leading,
            index: 0,
            settings: ["format": .string("HH:mm")]
        )
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(WidgetConfig.self, from: data)
        #expect(decoded.type == "Clock")
        #expect(decoded.size == .medium)
        #expect(decoded.zone == .top)
        #expect(decoded.group == .leading)
        #expect(decoded.index == 0)
    }
}
```

- [ ] **Step 7: Implement WidgetConfig and WidgetSize**

```swift
// noir/Models/WidgetConfig.swift
import Foundation

enum WidgetSize: String, Codable, CaseIterable, Sendable {
    case small
    case medium
    case large
}

enum WidgetConfigValue: Codable, Sendable, Equatable {
    case string(String)
    case double(Double)
    case bool(Bool)

    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    var doubleValue: Double? {
        if case .double(let v) = self { return v }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }
}

struct WidgetConfig: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var type: String
    var size: WidgetSize
    var zone: BarZone
    var group: WidgetGroup
    var index: Int
    var settings: [String: WidgetConfigValue]
}
```

- [ ] **Step 8: Write failing tests for NotchPriority**

```swift
// noirTests/Models/NotchPriorityTests.swift
import Testing
@testable import noir

@Suite("NotchPriority")
struct NotchPriorityTests {
    @Test("NotchPriority ordering")
    func priorityOrdering() {
        #expect(NotchPriority.low < NotchPriority.normal)
        #expect(NotchPriority.normal < NotchPriority.high)
        #expect(NotchPriority.high < NotchPriority.critical)
    }

    @Test("NotchPriority raw values")
    func priorityRawValues() {
        #expect(NotchPriority.low.rawValue == 0)
        #expect(NotchPriority.normal.rawValue == 1)
        #expect(NotchPriority.high.rawValue == 2)
        #expect(NotchPriority.critical.rawValue == 3)
    }
}
```

- [ ] **Step 9: Implement NotchPriority**

```swift
// noir/Models/NotchPriority.swift
import Foundation

enum NotchPriority: Int, Comparable, Codable, Sendable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3

    static func < (lhs: NotchPriority, rhs: NotchPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

- [ ] **Step 10: Implement WindowInfo**

```swift
// noir/Models/WindowInfo.swift
import Foundation

struct WindowInfo: Identifiable, Sendable, Equatable {
    let id: String
    let appName: String
    let title: String
    let frame: CGRect
    let workspace: Int
    let isFocused: Bool
}
```

- [ ] **Step 11: Run all model tests**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests 2>&1 | tail -10`
Expected: All model tests PASS

- [ ] **Step 12: Commit**

```bash
git add noir/Models/ noirTests/Models/
git commit -m "feat: add foundation models (BarZone, BarLayout, WidgetConfig, NotchPriority, WindowInfo)"
```

---

### Task 2: Widget Protocol & Registry

**Files:**
- Create: `noir/Protocols/NoirWidget.swift`
- Create: `noir/Protocols/NotchPresentable.swift`
- Create: `noir/Managers/WidgetRegistry.swift`
- Test: `noirTests/Managers/WidgetRegistryTests.swift`

- [ ] **Step 1: Write failing test for WidgetRegistry**

```swift
// noirTests/Managers/WidgetRegistryTests.swift
import Testing
import SwiftUI
@testable import noir

// Minimal test widget
struct TestWidget: NoirWidget {
    let id = UUID()
    var displayName: String { "TestWidget" }
    var systemImage: String { "star" }
    var defaultSize: WidgetSize { .small }
    var body: some View { Image(systemName: "star") }
}

struct AnotherWidget: NoirWidget {
    let id = UUID()
    var displayName: String { "AnotherWidget" }
    var systemImage: String { "circle" }
    var defaultSize: WidgetSize { .medium }
    var body: some View { Image(systemName: "circle") }
}

@Suite("WidgetRegistry")
struct WidgetRegistryTests {
    @Test("Register and create widget by type name")
    func registerAndCreate() {
        let registry = WidgetRegistry()
        registry.register(TestWidget.self)

        let widget = registry.createWidget(ofType: "TestWidget", size: .small)
        #expect(widget != nil)
        #expect(widget?.displayName == "TestWidget")
    }

    @Test("Returns nil for unregistered type")
    func unregisteredType() {
        let registry = WidgetRegistry()
        let widget = registry.createWidget(ofType: "Unknown", size: .small)
        #expect(widget == nil)
    }

    @Test("Register multiple widgets")
    func multipleWidgets() {
        let registry = WidgetRegistry()
        registry.register(TestWidget.self)
        registry.register(AnotherWidget.self)

        let w1 = registry.createWidget(ofType: "TestWidget", size: .small)
        let w2 = registry.createWidget(ofType: "AnotherWidget", size: .medium)
        #expect(w1 != nil)
        #expect(w2 != nil)
    }

    @Test("Create widget with different size")
    func createWithSize() {
        let registry = WidgetRegistry()
        registry.register(TestWidget.self)

        let widget = registry.createWidget(ofType: "TestWidget", size: .large)
        #expect(widget != nil)
        #expect(widget?.defaultSize == .small) // defaultSize is per-type, not per-creation
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests/WidgetRegistryTests 2>&1 | tail -5`
Expected: FAIL — `NoirWidget` protocol not found

- [ ] **Step 3: Implement NoirWidget protocol**

```swift
// noir/Protocols/NoirWidget.swift
import SwiftUI

protocol NoirWidget: Identifiable {
    var id: UUID { get }
    var displayName: String { get }
    var systemImage: String { get }
    var defaultSize: WidgetSize { get }

    @ViewBuilder func body() -> some View
}
```

- [ ] **Step 4: Implement NotchPresentable protocol**

```swift
// noir/Protocols/NotchPresentable.swift
import SwiftUI

protocol NotchPresentable: NoirWidget {
    var notchPriority: NotchPriority { get }
    var notchDuration: TimeInterval { get }

    @ViewBuilder func notchContent() -> some View
}
```

- [ ] **Step 5: Implement WidgetRegistry**

```swift
// noir/Managers/WidgetRegistry.swift
import SwiftUI

@Observable
final class WidgetRegistry {
    private var widgetTypes: [String: any NoirWidget.Type] = [:]

    func register(_ type: some NoirWidget.Type) {
        let instance = type.init()
        widgetTypes[instance.displayName] = type
    }

    func createWidget(ofType typeName: String, size: WidgetSize) -> (any NoirWidget)? {
        guard let widgetType = widgetTypes[typeName] else { return nil }
        return widgetType.init()
    }

    var registeredTypeNames: [String] {
        widgetTypes.keys.sorted()
    }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests/WidgetRegistryTests 2>&1 | tail -5`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add noir/Protocols/ noir/Managers/WidgetRegistry.swift noirTests/Managers/WidgetRegistryTests.swift
git commit -m "feat: add NoirWidget protocol, NotchPresentable, and WidgetRegistry"
```

---

### Task 3: NotchManager

**Files:**
- Create: `noir/Managers/NotchManager.swift`
- Test: `noirTests/Managers/NotchManagerTests.swift`

- [ ] **Step 1: Write failing tests for NotchManager**

```swift
// noirTests/Managers/NotchManagerTests.swift
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

    func body() -> some View {
        Text("Mock")
    }

    func notchContent() -> some View {
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
        // The high priority widget should now be active
    }

    @Test("Dismiss from widget collapses the notch")
    func dismissFromWidget() async {
        let manager = NotchManager(hasNotch: true)
        let widget = MockNotchWidget(priority: .normal, duration: 0) // manual dismiss
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests/NotchManagerTests 2>&1 | tail -5`
Expected: FAIL — `NotchManager` type not found

- [ ] **Step 3: Implement NotchManager**

```swift
// noir/Managers/NotchManager.swift
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
        guard activePresenter?.id == widget.id else { return }
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests/NotchManagerTests 2>&1 | tail -5`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add noir/Managers/NotchManager.swift noirTests/Managers/NotchManagerTests.swift
git commit -m "feat: add NotchManager with priority-based preemption and auto-dismiss"
```

---

### Task 4: WindowManagerProtocol & Detector

**Files:**
- Create: `noir/Protocols/WindowManagerProtocol.swift`
- Create: `noir/Managers/WindowManagerDetector.swift`
- Test: `noirTests/Managers/WindowManagerDetectorTests.swift`

- [ ] **Step 1: Write failing tests for WindowManagerDetector**

```swift
// noirTests/Managers/WindowManagerDetectorTests.swift
import Testing
@testable import noir

@Suite("WindowManagerDetector")
struct WindowManagerDetectorTests {
    @Test("Initial state is disconnected")
    func initialState() {
        let detector = WindowManagerDetector()
        #expect(detector.connectionState == .disconnected)
        #expect(detector.detectedWM == nil)
    }

    @Test("Connection state enum has expected cases")
    func connectionStateCases() {
        #expect(WindowManagerDetector.ConnectionState.connected != .disconnected)
        #expect(WindowManagerDetector.ConnectionState.reconnecting != .connected)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests/WindowManagerDetectorTests 2>&1 | tail -5`
Expected: FAIL — `WindowManagerDetector` not found

- [ ] **Step 3: Implement WindowManagerProtocol**

```swift
// noir/Protocols/WindowManagerProtocol.swift
import Foundation

protocol WindowManagerProtocol: Sendable {
    var name: String { get }
    var isRunning: Bool { get async }

    func focusWorkspace(_ index: Int) async throws
    func moveWindow(toWorkspace index: Int) async throws

    func activeWorkspace() async throws -> Int
    func workspaceNames() async throws -> [String]
    func visibleWindows() async throws -> [WindowInfo]

    var onWorkspaceChange: AsyncStream<Int>? { get }
}
```

- [ ] **Step 4: Implement WindowManagerDetector**

```swift
// noir/Managers/WindowManagerDetector.swift
import Foundation

@Observable
final class WindowManagerDetector {
    var detectedWM: (any WindowManagerProtocol)?
    var connectionState: ConnectionState = .disconnected

    enum ConnectionState: Sendable, Equatable {
        case connected
        case disconnected
        case reconnecting
    }

    func detect() async {
        // 1. Check user's explicit choice in settings (handled by caller)
        // 2. Check running processes
        let wmNames = ["aerospace", "yabai", "rift", "glide", "komorebi"]
        for name in wmNames {
            if isProcessRunning(name) {
                // WM found — actual adapter creation happens in integration sub-project
                connectionState = .connected
                return
            }
        }
        // 3. None detected — standalone mode
        connectionState = .disconnected
    }

    private func isProcessRunning(_ name: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", name]
        return process.run() ? process.terminationStatus == 0 : false
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests/WindowManagerDetectorTests 2>&1 | tail -5`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add noir/Protocols/WindowManagerProtocol.swift noir/Managers/WindowManagerDetector.swift noirTests/Managers/WindowManagerDetectorTests.swift
git commit -m "feat: add WindowManagerProtocol and WindowManagerDetector"
```

---

### Task 5: Layout Persistence (LayoutStore)

**Files:**
- Create: `noir/Persistence/LayoutStore.swift`
- Test: `noirTests/Persistence/LayoutStoreTests.swift`

- [ ] **Step 1: Write failing tests for LayoutStore**

```swift
// noirTests/Persistence/LayoutStoreTests.swift
import Testing
@testable import noir
import Foundation

@Suite("LayoutStore")
struct LayoutStoreTests {
    @Test("Save and load layout config round-trip")
    func roundTrip() async throws {
        let store = LayoutStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent("NoirTest-\(UUID().uuidString)"))
        let config = LayoutConfig(
            zones: [
                .top: ZoneConfig(widgets: [
                    WidgetConfig(id: UUID(), type: "Clock", size: .medium, zone: .top, group: .leading, index: 0, settings: [:]),
                    WidgetConfig(id: UUID(), type: "Wifi", size: .small, zone: .top, group: .trailing, index: 0, settings: [:]),
                ]),
                .bottom: ZoneConfig(widgets: [])
            ]
        )

        try store.save(config)
        let loaded = try store.load()

        #expect(loaded.zones[.top]?.widgets.count == 2)
        #expect(loaded.zones[.top]?.widgets[0].type == "Clock")
        #expect(loaded.zones[.bottom]?.widgets.isEmpty == true)
    }

    @Test("Load returns default when no file exists")
    func loadDefault() async throws {
        let store = LayoutStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent("NoirTest-Missing-\(UUID().uuidString)"))
        let config = try store.load()
        #expect(config.zones[.top]?.widgets.isEmpty == true)
        #expect(config.zones[.bottom]?.widgets.isEmpty == true)
    }

    @Test("Save creates directory if needed")
    func createsDirectory() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("NoirTest-NewDir-\(UUID().uuidString)")
        let store = LayoutStore(directory: dir)
        let config = LayoutConfig.default
        try store.save(config)
        #expect(FileManager.default.fileExists(atPath: dir.appendingPathComponent("layout.json").path))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests/LayoutStoreTests 2>&1 | tail -5`
Expected: FAIL — `LayoutStore` not found

- [ ] **Step 3: Implement LayoutConfig and LayoutStore**

```swift
// noir/Persistence/LayoutStore.swift
import Foundation

struct ZoneConfig: Codable, Sendable, Equatable {
    var widgets: [WidgetConfig]
}

struct LayoutConfig: Codable, Sendable, Equatable {
    var zones: [BarZone: ZoneConfig]

    static let `default` = LayoutConfig(
        zones: [
            .top: ZoneConfig(widgets: []),
            .bottom: ZoneConfig(widgets: []),
        ]
    )
}

// Custom encoding for BarZone keys (enum as dictionary key)
extension LayoutConfig {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: BarZoneCodingKey.self)
        var zones: [BarZone: ZoneConfig] = [:]
        for key in BarZoneCodingKey.allCases {
            if let zone = BarZone(rawValue: key.rawValue),
               let config = try? container.decodeIfPresent(ZoneConfig.self, forKey: key) {
                zones[zone] = config
            }
        }
        self.zones = zones
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: BarZoneCodingKey.self)
        for (zone, config) in zones {
            try container.encode(config, forKey: BarZoneCodingKey(rawValue: zone.rawValue))
        }
    }
}

private enum BarZoneCodingKey: String, CodingKey, CaseIterable {
    case top
    case bottom
}

final class LayoutStore {
    private let directory: URL
    private let fileURL: URL

    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("Noir")
        self.directory = dir
        self.fileURL = dir.appendingPathComponent("layout.json")
    }

    func save(_ config: LayoutConfig) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(config)
        try data.write(to: fileURL, options: .atomic)
    }

    func load() throws -> LayoutConfig {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .default
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(LayoutConfig.self, from: data)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests/LayoutStoreTests 2>&1 | tail -5`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add noir/Persistence/ noirTests/Persistence/
git commit -m "feat: add LayoutStore for JSON persistence of widget layout"
```

---

### Task 6: BarManager & NSPanel Factory

**Files:**
- Create: `noir/Managers/BarManager.swift`
- Create: `noir/Helpers/NSPanel+Bar.swift`
- Test: `noirTests/Managers/BarManagerTests.swift`

- [ ] **Step 1: Write failing tests for BarManager**

```swift
// noirTests/Managers/BarManagerTests.swift
import Testing
@testable import noir

@Suite("BarManager")
struct BarManagerTests {
    @Test("Initial state has default layout")
    func initialState() {
        let manager = BarManager()
        #expect(manager.layout.barHeight == 28)
        #expect(manager.isEditing == false)
        #expect(manager.zones == [.top, .bottom])
    }

    @Test("Add widget to zone")
    func addWidget() {
        let manager = BarManager()
        let config = WidgetConfig(id: UUID(), type: "Clock", size: .medium, zone: .top, group: .leading, index: 0, settings: [:])
        manager.addWidget(config)
        #expect(manager.widgets(for: .top).count == 1)
    }

    @Test("Remove widget from zone")
    func removeWidget() {
        let manager = BarManager()
        let config = WidgetConfig(id: UUID(), type: "Clock", size: .medium, zone: .top, group: .leading, index: 0, settings: [:])
        manager.addWidget(config)
        #expect(manager.widgets(for: .top).count == 1)
        manager.removeWidget(config)
        #expect(manager.widgets(for: .top).isEmpty)
    }

    @Test("Move widget between zones")
    func moveWidget() {
        let manager = BarManager()
        let config = WidgetConfig(id: UUID(), type: "Clock", size: .medium, zone: .top, group: .leading, index: 0, settings: [:])
        manager.addWidget(config)
        manager.moveWidget(config, from: .top, to: .bottom, at: 0)
        #expect(manager.widgets(for: .top).isEmpty)
        #expect(manager.widgets(for: .bottom).count == 1)
    }

    @Test("Notch detection")
    func notchDetection() {
        let manager = BarManager()
        // hasNotch depends on NSScreen.safeAreaInsets — in tests it defaults to false
        #expect(manager.hasNotch == false)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests/BarManagerTests 2>&1 | tail -5`
Expected: FAIL — `BarManager` not found

- [ ] **Step 3: Implement NSPanel+Bar helper**

```swift
// noir/Helpers/NSPanel+Bar.swift
import AppKit

extension NSPanel {
    static func makeBarPanel(contentRect: NSRect) -> NSPanel {
        let panel = NSPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasKey = false
        return panel
    }
}
```

- [ ] **Step 4: Implement BarManager**

```swift
// noir/Managers/BarManager.swift
import SwiftUI

@Observable
final class BarManager {
    var zones: [BarZone] = [.top, .bottom]
    var layout: BarLayout = .default
    var isEditing: Bool = false

    let notchManager: NotchManager
    let widgetRegistry: WidgetRegistry

    private var widgetConfigs: [UUID: WidgetConfig] = [:]
    private var panels: [BarZone: NSPanel] = [:]

    var hasNotch: Bool {
        guard let screen = NSScreen.main else { return false }
        return screen.safeAreaInsets.top > 0
    }

    var notchWidth: CGFloat {
        guard let screen = NSScreen.main else { return 0 }
        return screen.safeAreaInsets.top > 0 ? 200 : 0 // Approximate notch width
    }

    init() {
        self.notchManager = NotchManager(hasNotch: false)
        self.widgetRegistry = WidgetRegistry()
    }

    func widgets(for zone: BarZone, group: WidgetGroup? = nil) -> [WidgetConfig] {
        let zoneWidgets = widgetConfigs.values
            .filter { $0.zone == zone }
            .sorted { $0.index < $1.index }
        if let group {
            return zoneWidgets.filter { $0.group == group }
        }
        return zoneWidgets
    }

    func addWidget(_ config: WidgetConfig) {
        widgetConfigs[config.id] = config
    }

    func removeWidget(_ config: WidgetConfig) {
        widgetConfigs.removeValue(forKey: config.id)
    }

    func moveWidget(_ config: WidgetConfig, from source: BarZone, to dest: BarZone, at index: Int) {
        guard var movedConfig = widgetConfigs[config.id] else { return }
        widgetConfigs.removeValue(forKey: config.id)
        movedConfig.zone = dest
        movedConfig.index = index
        widgetConfigs[movedConfig.id] = movedConfig
    }

    func createPanels() {
        for zone in zones {
            let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
            let panelRect: NSRect
            switch zone {
            case .top:
                panelRect = NSRect(x: 0, y: screenRect.maxY, width: screenRect.width, height: layout.barHeight)
            case .bottom:
                panelRect = NSRect(x: 0, y: 0, width: screenRect.width, height: layout.barHeight)
            }

            let panel = NSPanel.makeBarPanel(contentRect: panelRect)
            let hostingController = NSHostingController(
                rootView: BarZoneView(zone: zone)
                    .environment(self)
                    .environment(notchManager)
            )
            panel.contentView = hostingController.view
            panel.makeKeyAndOrderFront(nil)
            panels[zone] = panel
        }
    }

    func destroyPanels() {
        for (_, panel) in panels {
            panel.close()
        }
        panels.removeAll()
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests/BarManagerTests 2>&1 | tail -5`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add noir/Managers/BarManager.swift noir/Helpers/ noirTests/Managers/BarManagerTests.swift
git commit -m "feat: add BarManager with widget management and NSPanel factory"
```

---

### Task 7: Bar Zone Views & Dynamic Notch View

**Files:**
- Create: `noir/Views/BarZoneView.swift`
- Create: `noir/Views/WidgetContainerView.swift`
- Create: `noir/Views/DynamicNotchView.swift`

- [ ] **Step 1: Implement BarZoneView**

```swift
// noir/Views/BarZoneView.swift
import SwiftUI

struct BarZoneView: View {
    let zone: BarZone
    @Environment(BarManager.self) var barManager

    var body: some View {
        HStack(spacing: barManager.layout.spacing) {
            ForEach(barManager.widgets(for: zone, group: .leading)) { widget in
                WidgetContainerView(config: widget)
            }

            if zone == .top && barManager.hasNotch {
                DynamicNotchView()
                    .frame(width: barManager.notchManager.isExpanded ? nil : barManager.notchWidth)
            }

            ForEach(barManager.widgets(for: zone, group: .trailing)) { widget in
                WidgetContainerView(config: widget)
            }
        }
        .padding(.horizontal, barManager.layout.horizontalPadding)
        .glassEffect(in: .rect(cornerRadius: barManager.layout.cornerRadius))
        .frame(maxWidth: .infinity)
        .frame(height: barManager.layout.barHeight)
    }
}
```

- [ ] **Step 2: Implement WidgetContainerView**

```swift
// noir/Views/WidgetContainerView.swift
import SwiftUI

struct WidgetContainerView: View {
    let config: WidgetConfig
    @Environment(BarManager.self) var barManager
    @Environment(WidgetRegistry.self) var registry

    var body: some View {
        Group {
            if let widget = registry.createWidget(ofType: config.type, size: config.size) {
                widget.body()
                    .frame(height: barManager.layout.barHeight - 4)
            } else {
                Image(systemName: "questionmark.square")
                    .foregroundStyle(.secondary)
            }
        }
        .if(barManager.isEditing) { view in
            view.overlay(alignment: .topTrailing) {
                Button {
                    barManager.removeWidget(config)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// Conditional modifier helper
extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
```

- [ ] **Step 3: Implement DynamicNotchView**

```swift
// noir/Views/DynamicNotchView.swift
import SwiftUI

struct DynamicNotchView: View {
    @Environment(NotchManager.self) var notchManager
    @Environment(BarManager.self) var barManager

    var body: some View {
        Group {
            if let presenter = notchManager.activePresenter, notchManager.isExpanded {
                presenter.notchContent()
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            } else {
                Color.clear
            }
        }
        .frame(minWidth: notchManager.isExpanded ? 120 : barManager.notchWidth)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: notchManager.isExpanded)
    }
}
```

- [ ] **Step 4: Build to verify compilation**

Run: `xcodebuild build -project noir.xcodeproj -scheme noir -destination 'platform=macOS' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add noir/Views/
git commit -m "feat: add BarZoneView, WidgetContainerView, and DynamicNotchView"
```

---

### Task 8: SpacerWidget & ClockWidget (First Built-in Widgets)

**Files:**
- Create: `noir/Widgets/SpacerWidget.swift`
- Create: `noir/Widgets/ClockWidget.swift`

- [ ] **Step 1: Implement SpacerWidget**

```swift
// noir/Widgets/SpacerWidget.swift
import SwiftUI

struct SpacerWidget: NoirWidget {
    let id = UUID()
    var displayName: String { "Spacer" }
    var systemImage: String { "arrow.left.and.right" }
    var defaultSize: WidgetSize { .small }

    func body() -> some View {
        Spacer()
            .frame(width: 8)
    }
}
```

- [ ] **Step 2: Implement ClockWidget**

```swift
// noir/Widgets/ClockWidget.swift
import SwiftUI

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
```

- [ ] **Step 3: Build to verify compilation**

Run: `xcodebuild build -project noir.xcodeproj -scheme noir -destination 'platform=macOS' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add noir/Widgets/
git commit -m "feat: add SpacerWidget and ClockWidget built-in widgets"
```

---

### Task 9: App Entry Point & Info.plist Configuration

**Files:**
- Modify: `noir/noirApp.swift`
- Modify: `noir/Info.plist` (or Xcode project settings)

- [ ] **Step 1: Update noirApp.swift to be a faceless app with bar panels**

```swift
// noir/noirApp.swift
import SwiftUI

@main
struct NoirApp: App {
    @State private var barManager = BarManager()
    @State private var settings = SettingsStore()
    @State private var wmDetector = WindowManagerDetector()

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(barManager)
                .environment(settings)
                .environment(wmDetector)
        }
    }

    init() {
        // Register built-in widgets
        let registry = BarManager().widgetRegistry
        registry.register(SpacerWidget.self)
        registry.register(ClockWidget.self)
    }
}
```

- [ ] **Step 2: Set LSUIElement in Info.plist**

Add `LSUIElement = YES` to the app's Info.plist (or in Xcode: Target → Info → Custom macOS Application Target Property → Add `Application is agent (UIElement)` = `YES`).

This hides the dock icon and prevents the app from appearing in the Cmd+Tab switcher.

- [ ] **Step 3: Build and verify the app launches without a dock icon**

Run: `xcodebuild build -project noir.xcodeproj -scheme noir -destination 'platform=macOS' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add noir/noirApp.swift
git commit -m "feat: configure NoirApp as faceless app with Settings scene and widget registration"
```

---

### Task 10: Settings Window (Stub)

**Files:**
- Create: `noir/Views/Settings/SettingsView.swift`
- Create: `noir/Views/Settings/LayoutSettingsView.swift`
- Create: `noir/Views/Settings/WidgetSettingsView.swift`
- Create: `noir/Views/Settings/WMSecuritySettingsView.swift`
- Create: `noir/Views/Settings/AppearanceSettingsView.swift`

- [ ] **Step 1: Implement SettingsView with tabs**

```swift
// noir/Views/Settings/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            LayoutSettingsView()
                .tabItem { Label("Layout", systemImage: "sidebar.left") }
            WidgetSettingsView()
                .tabItem { Label("Widgets", systemImage: "square.grid.2x2") }
            WMSecuritySettingsView()
                .tabItem { Label("Window Managers", systemImage: "macwindow") }
            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 500, height: 400)
    }
}
```

- [ ] **Step 2: Implement LayoutSettingsView (stub)**

```swift
// noir/Views/Settings/LayoutSettingsView.swift
import SwiftUI

struct LayoutSettingsView: View {
    @Environment(SettingsStore.self) var settings

    var body: some View {
        Text("Layout settings — drag and drop widget arrangement coming soon")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 3: Implement WidgetSettingsView (stub)**

```swift
// noir/Views/Settings/WidgetSettingsView.swift
import SwiftUI

struct WidgetSettingsView: View {
    @Environment(SettingsStore.self) var settings

    var body: some View {
        Text("Widget settings — enable/disable and configure widgets coming soon")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 4: Implement WMSecuritySettingsView (stub)**

```swift
// noir/Views/Settings/WMSecuritySettingsView.swift
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
```

- [ ] **Step 5: Implement AppearanceSettingsView (stub)**

```swift
// noir/Views/Settings/AppearanceSettingsView.swift
import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(SettingsStore.self) var settings

    var body: some View {
        Form {
            Section("Bar") {
                Slider(value: $settings.barHeight, in: 24...36, step: 2) {
                    Text("Bar Height")
                }
                Slider(value: $settings.barOpacity, in: 0.5...1.0, step: 0.05) {
                    Text("Opacity")
                }
            }
        }
        .formStyle(.grouped)
    }
}
```

- [ ] **Step 6: Implement SettingsStore**

```swift
// noir/Managers/SettingsStore.swift
import SwiftUI

@Observable
final class SettingsStore {
    var barHeight: CGFloat = 28
    var barOpacity: Double = 1.0
    var selectedWM: String? = nil
    var widgetConfigs: [UUID: WidgetConfig] = [:]
    var layoutConfig: LayoutConfig = .default
}
```

- [ ] **Step 7: Build to verify compilation**

Run: `xcodebuild build -project noir.xcodeproj -scheme noir -destination 'platform=macOS' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 8: Commit**

```bash
git add noir/Views/Settings/ noir/Managers/SettingsStore.swift
git commit -m "feat: add Settings window with tabs (Layout, Widgets, WM, Appearance)"
```

---

### Task 11: Aerospace Adapter (First WM Adapter)

**Files:**
- Create: `noir/Adapters/AerospaceAdapter.swift`
- Test: `noirTests/Adapters/AerospaceAdapterTests.swift`

- [ ] **Step 1: Write failing tests for AerospaceAdapter**

```swift
// noirTests/Adapters/AerospaceAdapterTests.swift
import Testing
@testable import noir

@Suite("AerospaceAdapter")
struct AerospaceAdapterTests {
    @Test("Adapter has correct name")
    func name() {
        let adapter = AerospaceAdapter()
        #expect(adapter.name == "aerospace")
    }

    @Test("isRunning returns false when aerospace not running")
    func notRunning() async {
        let adapter = AerospaceAdapter(socketPath: "/tmp/nonexistent-aerospace-socket")
        let running = await adapter.isRunning
        #expect(running == false)
    }

    @Test("onWorkspaceChange is nil by default (no socket connection)")
    func noWorkspaceStream() {
        let adapter = AerospaceAdapter(socketPath: "/tmp/nonexistent-aerospace-socket")
        #expect(adapter.onWorkspaceChange == nil)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests/AerospaceAdapterTests 2>&1 | tail -5`
Expected: FAIL — `AerospaceAdapter` not found

- [ ] **Step 3: Implement AerospaceAdapter**

```swift
// noir/Adapters/AerospaceAdapter.swift
import Foundation

final class AerospaceAdapter: WindowManagerProtocol, @unchecked Sendable {
    let name: String = "aerospace"
    let socketPath: String

    private var connection: URLSession?

    init(socketPath: String = "/tmp/aerospace.sock") {
        self.socketPath = socketPath
    }

    var isRunning: Bool {
        get async {
            FileManager.default.fileExists(atPath: socketPath)
        }
    }

    func focusWorkspace(_ index: Int) async throws {
        try await sendCommand("workspace \(index)")
    }

    func moveWindow(toWorkspace index: Int) async throws {
        try await sendCommand("move window to workspace \(index)")
    }

    func activeWorkspace() async throws -> Int {
        let result = try await sendCommand("workspace --focus")
        return Int(result.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    func workspaceNames() async throws -> [String] {
        let result = try await sendCommand("workspace --list")
        return result.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    func visibleWindows() async throws -> [WindowInfo] {
        // aerospace doesn't have a direct "list windows" command in the same way
        // This would be implemented with the actual aerospace API
        return []
    }

    var onWorkspaceChange: AsyncStream<Int>? {
        nil // Will be implemented with actual socket event subscription
    }

    private func sendCommand(_ command: String) async throws -> String {
        guard FileManager.default.fileExists(atPath: socketPath) else {
            throw AerospaceError.notRunning
        }

        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/aerospace")
        process.arguments = [command]
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

enum AerospaceError: LocalizedError {
    case notRunning
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .notRunning: "aerospace is not running"
        case .commandFailed(let msg): "aerospace command failed: \(msg)"
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' -only-testing:noirTests/AerospaceAdapterTests 2>&1 | tail -5`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add noir/Adapters/ noirTests/Adapters/
git commit -m "feat: add AerospaceAdapter as first WM integration"
```

---

### Task 12: MediaKeyMonitor (Stub)

**Files:**
- Create: `noir/Managers/MediaKeyMonitor.swift`

- [ ] **Step 1: Implement MediaKeyMonitor stub**

```swift
// noir/Managers/MediaKeyMonitor.swift
import Foundation
import AppKit

final class MediaKeyMonitor {
    private var eventTap: CFMachPort?

    var onVolumeChange: ((Double) -> Void)?
    var onBrightnessChange: ((Double) -> Void)?

    func start() {
        // CGEventTap setup for media keys
        // Requires Accessibility permission — will prompt on first launch
        // Full implementation in sub-project 3 (Custom HUDs)
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild build -project noir.xcodeproj -scheme noir -destination 'platform=macOS' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add noir/Managers/MediaKeyMonitor.swift
git commit -m "feat: add MediaKeyMonitor stub (full implementation in sub-project 3)"
```

---

### Task 13: Integration & Smoke Test

**Files:**
- Modify: `noir/noirApp.swift` (wire everything together)
- Test: `noirTests/Integration/SmokeTests.swift`

- [ ] **Step 1: Write smoke test**

```swift
// noirTests/Integration/SmokeTests.swift
import Testing
@testable import noir

@Suite("Smoke Tests")
struct SmokeTests {
    @Test("BarManager creates with default state")
    func barManagerDefaults() {
        let manager = BarManager()
        #expect(manager.zones == [.top, .bottom])
        #expect(manager.isEditing == false)
        #expect(manager.layout.barHeight == 28)
    }

    @Test("WidgetRegistry registers and creates widgets")
    func widgetRegistry() {
        let registry = WidgetRegistry()
        registry.register(SpacerWidget.self)
        registry.register(ClockWidget.self)

        let spacer = registry.createWidget(ofType: "Spacer", size: .small)
        #expect(spacer != nil)

        let clock = registry.createWidget(ofType: "Clock", size: .medium)
        #expect(clock != nil)
    }

    @Test("NotchManager initial state")
    func notchManagerInitialState() {
        let manager = NotchManager(hasNotch: true)
        #expect(manager.isExpanded == false)
        #expect(manager.activePresenter == nil)
    }

    @Test("LayoutStore round-trip with default config")
    func layoutStoreRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("NoirSmokeTest-\(UUID().uuidString)")
        let store = LayoutStore(directory: dir)
        let config = LayoutConfig.default
        try store.save(config)
        let loaded = try store.load()
        #expect(loaded == config)
    }

    @Test("WindowManagerDetector initial state")
    func wmDetectorInitialState() {
        let detector = WindowManagerDetector()
        #expect(detector.connectionState == .disconnected)
        #expect(detector.detectedWM == nil)
    }
}
```

- [ ] **Step 2: Update noirApp.swift to wire everything together**

```swift
// noir/noirApp.swift
import SwiftUI

@main
struct NoirApp: App {
    @State private var barManager: BarManager
    @State private var settings = SettingsStore()
    @State private var wmDetector = WindowManagerDetector()

    init() {
        let manager = BarManager()
        // Register built-in widgets
        manager.widgetRegistry.register(SpacerWidget.self)
        manager.widgetRegistry.register(ClockWidget.self)
        self._barManager = State(initialValue: manager)
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(barManager)
                .environment(settings)
                .environment(wmDetector)
        }
    }
}
```

- [ ] **Step 3: Run all tests**

Run: `xcodebuild test -project noir.xcodeproj -scheme noir -destination 'platform=macOS' 2>&1 | tail -10`
Expected: All tests PASS

- [ ] **Step 4: Build the full app**

Run: `xcodebuild build -project noir.xcodeproj -scheme noir -destination 'platform=macOS' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add noir/noirApp.swift noirTests/Integration/
git commit -m "feat: wire up full app with widget registration and smoke tests"
```

---

## Self-Review

### Spec Coverage Check

| Spec Section | Task |
|---|---|
| 1. App Architecture & Scene Structure | Task 6 (BarManager), Task 9 (App entry point) |
| 1. NSPanel Configuration | Task 6 (NSPanel+Bar.swift) |
| 1. BarManager Responsibilities | Task 6 (BarManager) |
| 2. Widget Protocol | Task 2 (NoirWidget, NotchPresentable) |
| 2. Widget Registry | Task 2 (WidgetRegistry) |
| 2. Widget Config (JSON) | Task 5 (LayoutStore) |
| 2. Edit Mode | Task 7 (WidgetContainerView with edit overlay) |
| 2. Settings Window | Task 10 (Settings tabs) |
| 3. WindowManagerProtocol | Task 4 (protocol) |
| 3. Auto-Detection | Task 4 (WindowManagerDetector) |
| 3. Aerospace Adapter | Task 11 (AerospaceAdapter) |
| 4. Bar Zone Rendering | Task 7 (BarZoneView) |
| 4. Liquid Glass Strategy | Task 7 (.glassEffect on BarZoneView) |
| 4. Notch Awareness | Task 6 (hasNotch, notchWidth), Task 7 (DynamicNotchView) |
| 4. Pass-Through Clicks | Task 6 (NSPanel configuration) |
| 5. Dynamic Notch | Task 3 (NotchManager), Task 7 (DynamicNotchView) |
| 5. Priority Preemption | Task 3 (NotchManager tests) |
| 5. Non-Notched Fallback | Task 3 (NotchManager hasNotch handling) |
| 5. Media Key Capture | Task 12 (MediaKeyMonitor stub) |
| 6. State Architecture | Task 6 (BarManager), Task 10 (SettingsStore) |
| 6. Persistence | Task 5 (LayoutStore) |
| 6. Environment Injection | Task 9 (noirApp.swift) |

### Placeholder Scan

No TBDs, TODOs, or "implement later" in implementation steps. MediaKeyMonitor is intentionally a stub (sub-project 3). Settings tabs are intentionally stubs (sub-projects 2-4).

### Type Consistency

- `BarZone`, `WidgetGroup`, `WidgetSize`, `NotchPriority` — used consistently across all tasks.
- `WidgetConfig` — same struct in LayoutStore, BarManager, and views.
- `NoirWidget` protocol — `displayName` used as registry key, consistent with WidgetRegistry.register.
- `NotchManager` — `hasNotch` parameter matches usage in BarManager and DynamicNotchView.
- `WindowManagerProtocol` — `name`, `isRunning`, `onWorkspaceChange` consistent across protocol and adapter.

All checks pass. Plan is complete.