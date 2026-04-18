# Noir — Core Bar Engine Design

**Date:** 2026-04-19  
**Status:** Approved  
**Sub-project:** 1 of 4 (Core Bar Engine → Built-in Widgets → Custom HUDs → Window Manager Integration)

---

## Overview

Noir is a native macOS app that replaces the system menu bar with a customizable, Liquid Glass-styled alternative. It provides drag-and-drop widget layout (iOS home screen style), an extensible dynamic notch for HUDs, and integration with tiling window managers.

**Target:** macOS 26 (Tahoe) only — Liquid Glass is a core visual requirement.  
**Architecture:** Zone-based NSPanels, Apple native patterns (@Observable), declarative config with future bundle support.

---

## 1. App Architecture & Scene Structure

Noir is a **faceless app** — no dock icon, no main window. It lives entirely in floating bar zones and a settings window.

### Scene Composition

```swift
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
}
```

- **No `WindowGroup`** — `LSUIElement = true` in Info.plist hides the dock icon.
- **`Settings` scene** — SwiftUI's built-in Settings gives us Cmd+, and proper window management.
- **Bar zones are created programmatically** — `BarManager` creates `NSPanel` instances via `NSHostingController`, not SwiftUI scenes. Full control over window level, collection behavior, and pass-through.

### NSPanel Configuration (Bar Zones)

```swift
panel.level = .screenSaver + 1
panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
panel.isMovableByWindowBackground = false
panel.hasShadow = false
panel.ignoresMouseEvents = false
panel.styleMask = [.borderless, .nonactivatingPanel]
panel.isOpaque = false
panel.backgroundColor = .clear
```

- `.screenSaver + 1` — above all app windows, below screen savers.
- `.nonactivatingPanel` — clicking the bar doesn't steal focus from the active app.
- `.borderless` + transparent background — clean canvas for Liquid Glass.
- `.canJoinAllSpaces` — bar persists across desktops.

### BarManager Responsibilities

- Create/destroy zone panels as configuration changes.
- Position panels on screen (notch-aware, multi-display).
- Handle screen layout changes (display added/removed, resolution change).
- Coordinate z-ordering between zones.
- Manage edit mode state for widget drag-and-drop.

---

## 2. Widget System & Plugin Architecture

### Widget Protocol

```swift
protocol NoirWidget: Identifiable {
    var id: UUID { get }
    var displayName: String { get }
    var systemImage: String { get }
    var defaultSize: WidgetSize { get }

    @ViewBuilder func body() -> some View
}

enum WidgetSize: String, Codable, CaseIterable {
    case small    // icon-only or single metric
    case medium   // icon + label + value
    case large    // expanded view (e.g., sound mixer)
}
```

Widgets are pure SwiftUI views. State lives in `@Observable` models injected via `@Environment`.

### Notch-Presentable Extension

```swift
protocol NotchPresentable: NoirWidget {
    var notchPriority: NotchPriority { get }
    var notchDuration: TimeInterval { get }  // 0 = manual dismiss only

    @ViewBuilder func notchContent() -> some View
}

enum NotchPriority: Int, Comparable {
    case low = 0        // Weather alerts, notifications
    case normal = 1     // Widget interactions (sound mixer expanding)
    case high = 2       // Media keys (volume, brightness)
    case critical = 3   // System alerts

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}
```

### Built-in Widgets (Phase 1)

| Widget | Size | Notch-Presentable | Priority |
|--------|------|-------------------|----------|
| `ClockWidget` | small/medium | No | — |
| `WifiWidget` | small | Yes | `.normal` (3s) |
| `SoundMixerWidget` | medium/large | Yes | `.normal` (manual) |
| `BrightnessWidget` | small | Yes | `.high` (2s) |
| `BatteryWidget` | small | Yes | `.low` (3s) |
| `ActiveAppWidget` | small/medium | No | — |
| `SpacerWidget` | small | No | — |

### Widget Configuration (Declarative JSON)

```json
{
  "zones": {
    "top": {
      "widgets": [
        { "type": "ActiveApp", "size": "medium" },
        { "type": "Spacer", "size": "small" },
        { "type": "Clock", "size": "medium" },
        { "type": "Wifi", "size": "small" },
        { "type": "Battery", "size": "small" }
      ]
    },
    "bottom": {
      "widgets": []
    }
  }
}
```

- `type` maps to a widget registry — `String: NoirWidget.Type`.
- Built-in widgets register automatically on launch.
- Future: bundle plugins register by declaring their type name in an `Info.plist` key.

### Widget Registry

```swift
@Observable
final class WidgetRegistry {
    private var widgetTypes: [String: NoirWidget.Type] = [:]

    func register(_ type: NoirWidget.Type) {
        widgetTypes[type.displayName] = type
    }

    func createWidget(ofType typeName: String, size: WidgetSize) -> NoirWidget? {
        guard let widgetType = widgetTypes[typeName] else { return nil }
        return widgetType.init(size: size)
    }
}
```

### Edit Mode (In-Bar)

When the user right-clicks or long-presses the bar:

1. Bar enters **edit mode** — widgets get a subtle wiggle animation (like iOS home screen).
2. Each widget shows a **drag handle** and **×** button.
3. Dragging reorders widgets within and between zones.
4. Tapping **×** removes a widget.
5. A **+** button at the end of each zone opens a widget picker sheet.
6. Pinching or tapping outside exits edit mode.

Layout changes persist to JSON config immediately on each drag-drop completion.

### Settings Window

A SwiftUI `Settings` scene with tabs:

- **Layout tab** — drag-and-drop editing in a window for precision.
- **Widgets tab** — enable/disable built-in widgets, configure per-widget settings.
- **Window Managers tab** — select and configure WM integration.
- **Appearance tab** — theme, Liquid Glass intensity, bar height, opacity.

---

## 3. Window Manager Integration

### Protocol Design

```swift
protocol WindowManagerProtocol {
    var name: String { get }
    var isRunning: Bool { get async }

    func focusWorkspace(_ index: Int) async throws
    func moveWindow(toWorkspace index: Int) async throws

    func activeWorkspace() async throws -> Int
    func workspaceNames() async throws -> [String]
    func visibleWindows() async throws -> [WindowInfo]

    var onWorkspaceChange: AsyncStream<Int>? { get }
}

struct WindowInfo: Identifiable {
    let id: String
    let appName: String
    let title: String
    let frame: CGRect
    let workspace: Int
    let isFocused: Bool
}
```

### Communication Patterns

| WM | IPC Method | Notes |
|----|-----------|-------|
| **aerospace** | Unix domain socket (JSON-RPC) | Fast, event-driven, best-documented API |
| **yabai** | Shell commands + Unix socket signals | Polling for queries, signals for events |
| **rift** | Shell commands | Newer WM, CLI-based |
| **glide** | TBD (likely CLI) | Still in development |
| **komorebi** | TCP socket | macOS port available, protocol documented |

Adapters wrap these differences behind the protocol. The rest of Noir never knows which WM is running.

### Auto-Detection

```swift
@Observable
final class WindowManagerDetector {
    var detectedWM: (any WindowManagerProtocol)?
    var connectionState: ConnectionState = .disconnected

    enum ConnectionState {
        case connected, disconnected, reconnecting
    }

    func detect() async {
        // 1. User's explicit choice in settings (highest priority)
        // 2. Running processes (pgrep aerospace, pgrep yabai, etc.)
        // 3. None detected → standalone mode (bar works, WM features disabled)
    }
}
```

### Integration Points

- **`ActiveAppWidget`** — shows focused app name + icon from `visibleWindows()`.
- **`WorkspaceIndicatorWidget`** (future) — workspace dots/numbers, click to switch.
- **`LayoutWidget`** (future) — current tiling layout, cycle options.

`BarManager` holds a reference to the active WM adapter and injects it into widgets via `@Environment`.

### Error Handling

- WM crashes/disconnects → widgets gracefully degrade (show "—" instead of crashing).
- `onWorkspaceChange` is optional — adapters without event support fall back to polling.
- Automatic reconnection with exponential backoff.

---

## 4. Bar Rendering & Liquid Glass

### Zone Panel Rendering

Each zone is an `NSPanel` hosting SwiftUI via `NSHostingController`:

```swift
struct BarZoneView: View {
    let zone: BarZone
    @Environment(BarManager.self) var barManager

    var body: some View {
        HStack(spacing: barManager.layout.spacing) {
            ForEach(barManager.widgets(for: zone, group: .leading)) { widget in
                WidgetContainerView(widget: widget)
            }

            if zone == .top && barManager.hasNotch {
                DynamicNotchView()
                    .frame(width: barManager.notchManager.isExpanded ? nil : barManager.notchWidth)
            }

            ForEach(barManager.widgets(for: zone, group: .trailing)) { widget in
                WidgetContainerView(widget: widget)
            }
        }
        .padding(.horizontal, barManager.layout.horizontalPadding)
        .glassEffect(in: .rect(cornerRadius: barManager.layout.cornerRadius))
        .frame(maxWidth: .infinity)
        .frame(height: barManager.layout.barHeight)
    }
}
```

### Liquid Glass Strategy

- **Bar zone** uses `.glassEffect()` (Regular variant) — navigation layer, exactly where Liquid Glass belongs.
- **Individual widgets** use `.glassEffect()` on interactive controls (buttons, sliders) but **not** on the widget container — avoids glass-on-glass stacking.
- **Widget content** (text, icons) uses standard foreground styles — SwiftUI's vibrant text handles legibility automatically.
- **Edit mode** adds a subtle `.glassEffect(.clear)` overlay on the entire bar to visually distinguish edit state.

### Notch Awareness

- `BarManager` reads `NSScreen.main?.safeAreaInsets` to detect notch width.
- On notched displays, the top bar splits into **leading** and **trailing** groups with a dynamic notch spacer between them.
- On non-notched displays, widgets flow freely in a single group.
- Bottom bar is never affected by the notch.

### Bar Height & Sizing

- Default: **28pt** (matching macOS menu bar height).
- Configurable: 24pt (compact) → 36pt (large).
- Widget sizes adapt to bar height — `small` fills the bar height, `medium`/`large` expand below as a popover or sheet.
- Bar respects `safeAreaInsets` — doesn't overlap the notch, sits below it.

### Pass-Through Clicks

Zone panels only cover the bar area. Clicks outside bar bounds go directly to apps below. For clicks **on** the bar:
- Widget taps → widget action.
- Empty space → pass through to app below (transparent regions use `ignoresMouseEvents`).

---

## 5. Dynamic Notch & HUD System

### Extensible Dynamic Notch

The notch is a **shared presentation space** that any `NotchPresentable` widget can claim. Priority-based preemption ensures important notifications always show.

### NotchManager

```swift
@Observable
final class NotchManager {
    private(set) var activePresenter: (any NotchPresentable)?
    private(set) var isExpanded: Bool = false
    private var dismissTask: Task<Void, Never>?

    let hasNotch: Bool  // From NSScreen safeAreaInsets

    func request(_ widget: some NotchPresentable, value: Double = 0, icon: String? = nil) {
        // Higher priority preempts current presenter
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
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(interval))
            dismissCurrent()
        }
    }
}
```

### Priority Preemption Rules

1. **Same priority** — new request queues behind current, shows after dismiss.
2. **Higher priority** — immediately preempts (e.g., volume key preempts weather alert).
3. **Critical priority** — always shows, never preempted (reserved for system alerts).
4. **Manual dismiss** (`duration: 0`) — widget controls its own lifecycle.

### Dynamic Notch View

```swift
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

### Non-Notched Display Fallback

`NotchManager` handles both cases — there is no separate `HUDManager`:

- **Notched Mac** → `NotchManager` expands the bar's notch spacer area. Content renders inside `DynamicNotchView` within the existing top bar `NSPanel`.
- **Non-notched Mac** → `NotchManager` creates a temporary floating `NSPanel` (centered at top of screen, same level as bar zones) and hosts the `notchContent()` in it. The panel auto-dismisses with the same timer.
- Widget code is identical — `notchContent()` is the same regardless of display type. Only the container changes.

### Media Key Capture

`CGEventTap` intercepts media key presses (volume up/down, brightness up/down):

```swift
final class MediaKeyMonitor {
    private var eventTap: CFMachPort?

    func start() {
        // Register for media key events
        // Forward to NotchManager.request()
    }

    func stop() {
        // Clean up event tap
    }
}
```

- Media key events trigger the dynamic notch and update system volume/brightness.
- The notch is purely visual feedback — it doesn't replace system volume control.
- Requires Accessibility permission (prompted on first launch).

---

## 6. Data Flow & State Architecture

### Architecture: Apple Native Patterns (@Observable)

Noir uses Apple's modern SwiftUI patterns — `@Observable` models, `@Environment` for dependency injection. No MVVM or TCA overhead.

Rationale:
- Noir is a utility app, not a complex data-driven app.
- Most state is UI-driven (widget positions, bar config, HUD state).
- `@Observable` gives granular dependency tracking for free.
- No network layer, no database — just local config and IPC to window managers.

### State Hierarchy

```
NoirApp
├── BarManager (@Environment)
│   ├── zones: [BarZone]
│   ├── layout: BarLayout
│   ├── isEditing: Bool
│   ├── notchManager: NotchManager
│   │   ├── activePresenter
│   │   ├── isExpanded
│   │   └── hasNotch
│   │   └── On non-notched Macs, NotchManager delegates to a floating NSPanel
│   │     instead of expanding the bar's notch spacer. No separate HUDManager needed.
│   └── widgetRegistry: WidgetRegistry
│       └── widgetTypes: [String: NoirWidget.Type]
│
├── WindowManagerDetector (@Environment)
│   ├── detectedWM: (any WindowManagerProtocol)?
│   └── connectionState: .connected | .disconnected | .reconnecting
│
├── SettingsStore (@Environment)
│   ├── barHeight: CGFloat
│   ├── barOpacity: Double
│   ├── selectedWM: String?
│   ├── widgetConfigs: [UUID: WidgetConfig]
│   └── layoutConfig: LayoutConfig
│
└── MediaKeyMonitor
    └── forwards events to NotchManager
```

### Key Models

```swift
enum BarZone: String, Codable, CaseIterable {
    case top
    case bottom
}

enum WidgetGroup: String, Codable {
    case leading
    case trailing
}

struct BarLayout: Codable {
    var barHeight: CGFloat = 28
    var cornerRadius: CGFloat = 0  // 0 = full-width bar, >0 = floating pill
    var spacing: CGFloat = 8
    var horizontalPadding: CGFloat = 12
}

struct WidgetConfig: Codable, Identifiable {
    let id: UUID
    let type: String           // "Clock", "Wifi", "SoundMixer", etc.
    var size: WidgetSize
    var zone: BarZone
    var group: WidgetGroup
    var index: Int             // Order within group
    var settings: [String: Value]  // Per-widget settings (JSON value)
}
```

### Environment Injection

Bar zone views get the environment via `NSHostingController`:

```swift
let hostingController = NSHostingController(
    rootView: BarZoneView(zone: .top)
        .environment(barManager)
        .environment(settings)
        .environment(wmDetector)
)
```

### Persistence

- **Widget layout** — JSON file in `~/Library/Application Support/Noir/layout.json`.
- **Settings** — `@AppStorage` for simple values, JSON file for complex config.
- **Window manager choice** — stored in settings, auto-detect if nil.
- Layout changes persist immediately on every drag-drop completion (not batched).

No database needed — all state fits in file-based persistence.

---

## Sub-Projects (Future Specs)

1. **Core Bar Engine** ← this spec
2. **Built-in Widgets** — Clock, Wi-Fi, Sound Mixer, Brightness, Battery, Active App, Spacer
3. **Custom HUDs** — Volume, Brightness, per-app volume, workspace switch
4. **Window Manager Integration** — aerospace, yabai, rift, glide, komorebi adapters

Each sub-project gets its own spec → plan → implementation cycle.