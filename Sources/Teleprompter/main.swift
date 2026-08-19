import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// .accessory = lives in the menu bar with no Dock icon; you start it from the
// terminal and control it from the menu bar item.
app.setActivationPolicy(.accessory)
app.run()
