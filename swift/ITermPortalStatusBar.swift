import AppKit
import Foundation

private struct TerminalOption {
    let title: String
    let appName: String
    let bundleIdentifier: String
}

private struct OpenModeOption {
    let title: String
    let value: String
}

private let terminalOptions: [TerminalOption] = [
    TerminalOption(title: "Terminal", appName: "Terminal", bundleIdentifier: "com.apple.Terminal"),
    TerminalOption(title: "iTerm2", appName: "iTerm", bundleIdentifier: "com.googlecode.iterm2"),
    TerminalOption(title: "Ghostty", appName: "Ghostty", bundleIdentifier: "com.mitchellh.ghostty"),
    TerminalOption(title: "Warp", appName: "Warp", bundleIdentifier: "dev.warp.Warp-Stable")
]

private let openModeOptions: [OpenModeOption] = [
    OpenModeOption(title: "New instance", value: "new_terminal"),
    OpenModeOption(title: "New window", value: "new_window"),
    OpenModeOption(title: "New tab", value: "new_tab")
]

private enum PreferenceStore {
    private static let defaultTerminal = "Terminal"
    private static let defaultOpenMode = "new_window"

    static func currentTerminal() -> String {
        readValue(from: terminalSettingsURL(), defaultValue: defaultTerminal)
    }

    static func setTerminal(_ appName: String) {
        writeValue(appName, to: terminalSettingsURL())
    }

    static func currentOpenMode() -> String {
        readValue(from: openModeSettingsURL(), defaultValue: defaultOpenMode)
    }

    static func setOpenMode(_ mode: String) {
        writeValue(mode, to: openModeSettingsURL())
    }

    private static func readValue(from url: URL, defaultValue: String) -> String {
        guard let data = try? Data(contentsOf: url),
              let value = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return defaultValue
        }
        return value
    }

    private static func writeValue(_ value: String, to url: URL) {
        let payload = "\(value)\n"
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? payload.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func baseSettingsURL() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport
            .appendingPathComponent("iTermPortal", isDirectory: true)
    }

    private static func terminalSettingsURL() -> URL {
        baseSettingsURL().appendingPathComponent("terminal_choice.txt", isDirectory: false)
    }

    private static func openModeSettingsURL() -> URL {
        baseSettingsURL().appendingPathComponent("open_mode.txt", isDirectory: false)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private var terminalItems: [String: NSMenuItem] = [:]
    private var openModeItems: [String: NSMenuItem] = [:]

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
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "iTP"
        }

        button.toolTip = "iTermPortal"
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
        let openInItem = NSMenuItem(title: "Open in", action: nil, keyEquivalent: "")
        openInItem.isEnabled = false
        menu.addItem(openInItem)

        for option in openModeOptions {
            let item = NSMenuItem(
                title: option.title,
                action: #selector(selectOpenMode(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = option.value
            menu.addItem(item)
            openModeItems[option.value] = item
        }

        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit iTermPortal Menu", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func refreshChecks() {
        let currentTerminal = PreferenceStore.currentTerminal()
        for (appName, item) in terminalItems {
            item.state = appName == currentTerminal ? .on : .off
        }

        let currentOpenMode = PreferenceStore.currentOpenMode()
        for (mode, item) in openModeItems {
            item.state = mode == currentOpenMode ? .on : .off
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

    @objc private func selectOpenMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? String else { return }
        PreferenceStore.setOpenMode(mode)
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
