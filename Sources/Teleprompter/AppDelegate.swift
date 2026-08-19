import AppKit
import SwiftUI

/// A borderless window still needs to accept keyboard focus (for editing +
/// shortcuts), so we opt in explicitly.
final class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var window: NSWindow!
    private let model = PrompterModel()
    private var keyMonitor: Any?
    private var scrollMonitor: Any?
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildAppMenu()
        buildStatusItem()

        let root = ContentView().environmentObject(model)
        let hosting = NSHostingView(rootView: root)

        window = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 190),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        window.level = .floating                       // stay above recording apps
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true      // drag from empty areas
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.minSize = NSSize(width: 220, height: 60)
        window.isReleasedWhenClosed = false
        window.alphaValue = model.opacity
        window.contentView = hosting

        positionUnderCamera()
        showWindow()

        installKeyMonitor()
        installScrollMonitor()
    }

    // MARK: Menu bar item
    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "captions.bubble.fill",
                                   accessibilityDescription: "Teleprompter")
            button.image?.isTemplate = true
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    /// Rebuild the menu each time it opens so titles reflect current state.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        add(menu, window.isVisible ? "Hide Teleprompter" : "Show Teleprompter", "s", #selector(menuToggleShow))
        add(menu, "Edit Script…", "e", #selector(menuEdit))
        menu.addItem(.separator())
        add(menu, "Quit Teleprompter", "q", #selector(NSApplication.terminate(_:)))
    }

    private func add(_ menu: NSMenu, _ title: String, _ key: String, _ action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = action == #selector(NSApplication.terminate(_:)) ? nil : self
        menu.addItem(item)
    }

    @objc private func menuEdit() { showWindow(); model.isEditing = true }
    @objc private func menuToggleShow() {
        if window.isVisible { window.orderOut(nil) } else { showWindow() }
    }

    private func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    /// Center horizontally, near the top of the main screen — right under the
    /// built-in camera.
    private func positionUnderCamera() {
        guard let screen = NSScreen.main else { window.center(); return }
        let vf = screen.visibleFrame
        let size = window.frame.size
        let x = vf.midX - size.width / 2
        let y = vf.maxY - size.height - 8
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: Mouse-wheel / trackpad scrubbing
    private func installScrollMonitor() {
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self = self else { return event }
            if self.model.isEditing { return event } // let the editor scroll normally

            // Option + scroll dials window opacity in real time; plain scroll
            // scrubs the script.
            if event.modifierFlags.contains(.option) {
                self.model.bumpOpacity(event.scrollingDeltaY * 0.004)
                self.window.alphaValue = self.model.opacity
            } else {
                self.model.scrollBy(-event.scrollingDeltaY)
            }
            return nil
        }
    }

    // MARK: Keyboard shortcuts (when the window is focused)
    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            return self.handle(event) ? nil : event
        }
    }

    /// Returns true if we handled (and should swallow) the event.
    private func handle(_ event: NSEvent) -> Bool {
        // Let Cmd-based shortcuts (Cmd-Q, copy/paste, etc.) work normally.
        if event.modifierFlags.contains(.command) { return false }

        // While editing, keystrokes belong to the text field — only Esc exits.
        if model.isEditing {
            if event.keyCode == 53 { // Esc
                model.isEditing = false
                return true
            }
            return false
        }

        switch event.charactersIgnoringModifiers {
        case " ": model.togglePlay(); return true
        case "r", "R": model.restart(); return true
        case "e", "E": model.isEditing = true; return true
        case "+", "=": model.bumpSpeed(5); return true
        case "-", "_": model.bumpSpeed(-5); return true
        case "]": model.bumpFont(2); return true
        case "[": model.bumpFont(-2); return true
        default: break
        }

        switch event.keyCode {
        case 126: model.scrollBy(-40); return true // Up arrow
        case 125: model.scrollBy(40);  return true // Down arrow
        case 53:  window.orderOut(nil); return true // Esc hides the window
        default: return false
        }
    }

    /// Minimal app menu so Cmd-Q and clipboard shortcuts work while editing.
    private func buildAppMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Teleprompter",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu

        NSApp.mainMenu = mainMenu
    }
}
