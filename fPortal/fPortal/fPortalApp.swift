//
//  fPortalApp.swift
//  fPortal
//
//  Created by Hugo Joncour on 2025-10-19.
//

import SwiftUI
import AppKit

@main
struct fPortalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Window that can be shown/hidden
        Window("fPortal Settings", id: "settings") {
            ContentView()
        }
        .defaultSize(width: 600, height: 700)
        .windowResizability(.contentSize)
        .commandsRemoved()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            if let image = NSImage(named: NSImage.Name("fPortal")) {
                image.isTemplate = true            // use template so it tints automatically
                button.image = image
            }
            button.action = #selector(toggleWindow)
            button.target = self
            button.toolTip = "fPortal — Click to open settings"
        }
    }
    
    @objc func toggleWindow() {
        // Find the settings window
        let settingsWindow = NSApplication.shared.windows.first { $0.title == "fPortal Settings" }
        
        if let window = settingsWindow, window.isVisible {
            // Window exists and is visible - hide it
            window.orderOut(nil)
        } else if let window = settingsWindow {
            // Window exists but is hidden - show it
            window.makeKeyAndOrderFront(nil)
            window.center()
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // Window doesn't exist - open it
            openSettings()
        }
    }
    
    @objc func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        
        // Try to open or create the window
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.center()
        } else {
            // Trigger window creation by opening URL scheme
            NSWorkspace.shared.open(URL(string: "fportal://settings")!)
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
