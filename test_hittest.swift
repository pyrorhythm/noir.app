import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 400, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.ignoresMouseEvents = false

        let view = ZStack {
            Rectangle()
                .fill(Color.red.opacity(0.5))
                .allowsHitTesting(false)
            
            Button("Click Me") {
                print("Button clicked")
            }
        }

        window.contentView = NSHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)
        
        // Quit after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            NSApplication.shared.terminate(nil)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
