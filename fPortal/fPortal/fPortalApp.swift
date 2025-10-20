//
//  fPortalApp.swift
//  fPortal
//

import SwiftUI
import AppKit

@main
struct fPortalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We manage the window manually (no automatic SwiftUI window)
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWC: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            if let img = NSImage(named: "MenuBarIcon") {
                img.isTemplate = true
                img.size = NSSize(width: 18, height: 18)       // 👈 tell AppKit the intended size
                button.image = img
                button.alternateImage = img
                button.imageScaling = .scaleProportionallyUpOrDown // 👈 avoid odd cropping
                button.imagePosition = .imageOnly
            } else if let sf = NSImage(systemSymbolName: "folder.badge.gearshape",
                                    accessibilityDescription: "fPortal") {
                sf.isTemplate = true
                button.image = sf
            }
            button.toolTip = "fPortal — Click to open / hide settings"
            button.target  = self
            button.action  = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp])
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // MARK: - Status item click → TOGGLE
    @objc private func statusItemClicked(_ sender: Any?) {
        if let win = settingsWC?.window {
            win.isVisible ? hideSettingsWindow() : showSettingsWindow()
        } else {
            showSettingsWindow()
        }
    }

    // MARK: - Window management
    private func showSettingsWindow() {
        if settingsWC == nil { settingsWC = makeSettingsWindow() }
        NSApp.activate(ignoringOtherApps: true)
        settingsWC?.showWindow(nil)
        settingsWC?.window?.center()
    }

    private func hideSettingsWindow() {
        settingsWC?.window?.orderOut(nil)
    }

    private func makeSettingsWindow() -> NSWindowController {
        let hosting = NSHostingController(rootView: ContentView())
        let window  = NSWindow(contentViewController: hosting)
        window.title = "fPortal Settings"
        window.setContentSize(NSSize(width: 600, height: 700))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        return NSWindowController(window: window)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
