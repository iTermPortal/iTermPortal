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

private final class AboutWindowController {
    private var window: NSWindow?

    func show() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "About iTermPortal"
        panel.isReleasedWhenClosed = false
        panel.center()
        panel.isMovableByWindowBackground = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.level = .floating

        let content = NSView(frame: panel.contentRect(forFrameRect: panel.frame))

        let imageView = NSImageView(frame: NSRect(x: 90, y: 140, width: 100, height: 100))
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: iconURL) {
            imageView.image = image
        }
        imageView.imageScaling = .scaleProportionallyUpOrDown
        content.addSubview(imageView)

        let nameLabel = NSTextField(labelWithString: "iTermPortal")
        nameLabel.font = NSFont.boldSystemFont(ofSize: 18)
        nameLabel.alignment = .center
        nameLabel.frame = NSRect(x: 0, y: 105, width: 280, height: 28)
        content.addSubview(nameLabel)

        let versionLabel = NSTextField(labelWithString: "Version \(version)")
        versionLabel.font = NSFont.systemFont(ofSize: 12)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.alignment = .center
        versionLabel.frame = NSRect(x: 0, y: 80, width: 280, height: 20)
        content.addSubview(versionLabel)

        let authorLabel = NSTextField(labelWithString: "by Hugo Joncour")
        authorLabel.font = NSFont.systemFont(ofSize: 12)
        authorLabel.textColor = .secondaryLabelColor
        authorLabel.alignment = .center
        authorLabel.frame = NSRect(x: 0, y: 55, width: 280, height: 20)
        content.addSubview(authorLabel)

        let copyrightLabel = NSTextField(labelWithString: "© 2025-2026 Hugo Joncour. All rights reserved.")
        copyrightLabel.font = NSFont.systemFont(ofSize: 10)
        copyrightLabel.textColor = .tertiaryLabelColor
        copyrightLabel.alignment = .center
        copyrightLabel.frame = NSRect(x: 0, y: 25, width: 280, height: 16)
        content.addSubview(copyrightLabel)

        panel.contentView = content
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = panel
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private var terminalItems: [String: NSMenuItem] = [:]
    private var openModeItems: [String: NSMenuItem] = [:]
    private let aboutController = AboutWindowController()

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
        let about = NSMenuItem(title: "About iTermPortal", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

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

    @objc private func showAbout() {
        aboutController.show()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
