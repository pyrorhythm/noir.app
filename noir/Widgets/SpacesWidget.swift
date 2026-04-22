import SwiftUI

struct SpacesWidget: NoirWidget {
    let id = UUID()
    var displayName: String { "Spaces" }
    var systemImage: String { "rectangle.3.group" }
    var defaultSize: WidgetSize { .large }

    var body: some View {
        SpacesWidgetView()
    }
}

private struct SpacesWidgetView: View {
    @Environment(WindowManagerDetector.self) private var wmDetector
    @State private var spaces: [SpaceItem] = []
    @State private var focusedWorkspace: String?

    var body: some View {
        HStack(spacing: 4) {
            if spaces.isEmpty {
                Image(systemName: "rectangle.3.group")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(spaces) { space in
                    Button {
                        focus(space)
                    } label: {
                        SpacePill(space: space)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task {
            await refreshLoop()
        }
    }

    private func refreshLoop() async {
        while !Task.isCancelled {
            await refresh()
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func refresh() async {
        guard let wm = wmDetector.detectedWM else {
            spaces = []
            focusedWorkspace = nil
            return
        }

        do {
            if let aerospace = wm as? AerospaceAdapter {
                let aeroSpaces = try await aerospace.spacesWithWindows()
                focusedWorkspace = aeroSpaces.first(where: \.isFocused)?.workspace
                spaces = aeroSpaces.map { space in
                    SpaceItem(
                        name: space.workspace,
                        isFocused: space.isFocused || space.windows.contains(where: \.isFocused),
                        windows: space.windows
                    )
                }
                return
            }

            async let names = wm.workspaceNames()
            async let windows = wm.visibleWindows()
            async let focused = wm.activeWorkspace()

            let resolvedNames = try await names
            let resolvedWindows = try await windows
            let resolvedFocused = try await focused
            let windowsBySpace = Dictionary(grouping: resolvedWindows, by: \.workspace)
            let allNames = orderedWorkspaceNames(resolvedNames, windowsBySpace: windowsBySpace)

            focusedWorkspace = resolvedFocused
            spaces = allNames.map { name in
                SpaceItem(
                    name: name,
                    isFocused: name == resolvedFocused || windowsBySpace[name]?.contains(where: \.isFocused) == true,
                    windows: windowsBySpace[name] ?? []
                )
            }
        } catch {
            spaces = []
        }
    }

    private func orderedWorkspaceNames(_ names: [String], windowsBySpace: [String: [WindowInfo]]) -> [String] {
        let windowNames = windowsBySpace.keys.sorted { lhs, rhs in
            switch (Int(lhs), Int(rhs)) {
            case let (lhsNumber?, rhsNumber?):
                lhsNumber < rhsNumber
            case (_?, nil):
                true
            case (nil, _?):
                false
            case (nil, nil):
                lhs < rhs
            }
        }
        let ordered = names.isEmpty ? windowNames : names
        return ordered.filter { !$0.isEmpty }
    }

    private func focus(_ space: SpaceItem) {
        Task {
            try? await wmDetector.detectedWM?.focusWorkspace(space.name)
            await refresh()
        }
    }
}

private struct SpacePill: View {
    let space: SpaceItem

    var body: some View {
        HStack(spacing: 4) {
            Text(space.name)
                .font(.system(size: 12, weight: space.isFocused ? .bold : .medium, design: .rounded))
                .monospacedDigit()

            ForEach(space.windows.prefix(4)) { window in
                Circle()
                    .fill(window.isFocused ? Color.primary : Color.secondary.opacity(0.65))
                    .frame(width: 4, height: 4)
            }
        }
        .padding(.horizontal, 7)
        .frame(height: 22)
        .background {
            Capsule()
                .fill(space.isFocused ? Color.primary.opacity(0.18) : Color.secondary.opacity(0.10))
        }
        .overlay {
            Capsule()
                .strokeBorder(space.isFocused ? Color.primary.opacity(0.28) : Color.clear, lineWidth: 0.75)
        }
    }
}

private struct SpaceItem: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let isFocused: Bool
    let windows: [WindowInfo]
}
