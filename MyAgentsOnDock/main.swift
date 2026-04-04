import AppKit

// 전통적인 NSApplication 진입점
// SwiftUI MenuBarExtra 대신 NSStatusItem + NSPopover 직접 사용
let app = NSApplication.shared
let delegate = MainActor.assumeIsolated { AppDelegate() }
app.delegate = delegate
app.run()
