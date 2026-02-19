import AppKit
import Foundation

private struct TerminalOption {
    let title: String
    let appName: String
    let bundleIdentifier: String
}

private let terminalOptions: [TerminalOption] = [
    TerminalOption(title: "Terminal", appName: "Terminal", bundleIdentifier: "com.apple.Terminal"),
    TerminalOption(title: "iTerm2", appName: "iTerm", bundleIdentifier: "com.googlecode.iterm2"),
    TerminalOption(title: "Ghostty", appName: "Ghostty", bundleIdentifier: "com.mitchellh.ghostty"),
    TerminalOption(title: "Warp", appName: "Warp", bundleIdentifier: "dev.warp.Warp-Stable")
]

private enum PreferenceStore {
    private static let defaultTerminal = "Terminal"

    static func currentTerminal() -> String {
        let url = settingsURL()
        guard let data = try? Data(contentsOf: url),
              let value = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return defaultTerminal
        }
        return value
    }

    static func setTerminal(_ appName: String) {
        let url = settingsURL()
        let value = "\(appName)\n"
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? value.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func settingsURL() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport
            .appendingPathComponent("fPortal", isDirectory: true)
            .appendingPathComponent("terminal_choice.txt", isDirectory: false)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private var terminalItems: [String: NSMenuItem] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configureMenu()
        refreshChecks()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: iconURL) {
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = false
            button.image = image
        } else {
            button.title = "fP"
        }

        button.toolTip = "fPortal"
        statusItem.menu = menu
    }

    private func configureMenu() {
        let titleItem = NSMenuItem(title: "Default Terminal", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())

        for option in terminalOptions {
            let item = NSMenuItem(
                title: option.title,
                action: #selector(selectTerminal(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = option.appName
            item.isEnabled = isTerminalInstalled(option)
            if !item.isEnabled {
                item.toolTip = "Not installed"
            }
            menu.addItem(item)
            terminalItems[option.appName] = item
        }

        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit fPortal Menu", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func refreshChecks() {
        let current = PreferenceStore.currentTerminal()
        for (appName, item) in terminalItems {
            item.state = appName == current ? .on : .off
        }
    }

    private func isTerminalInstalled(_ option: TerminalOption) -> Bool {
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: option.bundleIdentifier) != nil
    }

    @objc private func selectTerminal(_ sender: NSMenuItem) {
        guard let appName = sender.representedObject as? String else { return }
        PreferenceStore.setTerminal(appName)
        refreshChecks()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
