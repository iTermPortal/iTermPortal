import AppKit
import FinderSync
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private var terminalItems: [TerminalChoice: NSMenuItem] = [:]
    private var openModeItems: [OpenMode: NSMenuItem] = [:]
    private let aboutController = AboutWindowController()
    private var defaultsObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        PreferenceMigration.migrateIfNeeded()
        registerLoginItem()
        configureStatusItem()
        configureMenu()
        refreshChecks()
        OnboardingWindowController.shared.showIfNeeded()

        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshChecks()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }

    private func registerLoginItem() {
        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.register()
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        guard let image = (NSApp.applicationIconImage.copy() as? NSImage) ?? NSApp.applicationIconImage else {
            button.title = "iTP"
            button.toolTip = "iTermPortal"
            statusItem.menu = menu
            return
        }

        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        button.image = image
        button.toolTip = "iTermPortal"
        statusItem.menu = menu
    }

    private func configureMenu() {
        let terminalTitle = NSMenuItem(title: "Default Terminal", action: nil, keyEquivalent: "")
        terminalTitle.isEnabled = false
        menu.addItem(terminalTitle)
        menu.addItem(.separator())

        for terminalChoice in TerminalChoice.allCases {
            let item = NSMenuItem(
                title: terminalChoice.displayTitle,
                action: #selector(selectTerminal(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = terminalChoice.rawValue
            menu.addItem(item)
            terminalItems[terminalChoice] = item
        }

        menu.addItem(.separator())

        let openModeTitle = NSMenuItem(title: "Open In", action: nil, keyEquivalent: "")
        openModeTitle.isEnabled = false
        menu.addItem(openModeTitle)

        for openMode in OpenMode.allCases {
            let item = NSMenuItem(
                title: openMode.displayTitle,
                action: #selector(selectOpenMode(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = openMode.rawValue
            menu.addItem(item)
            openModeItems[openMode] = item
        }

        menu.addItem(.separator())

        let manageExtensionItem = NSMenuItem(
            title: "Manage Extension…",
            action: #selector(openExtensionPreferences),
            keyEquivalent: ""
        )
        manageExtensionItem.target = self
        menu.addItem(manageExtensionItem)

        let aboutItem = NSMenuItem(title: "About iTermPortal", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: "Quit iTermPortal", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func refreshChecks() {
        let preferences = SharedPreferences.shared

        for terminalChoice in TerminalChoice.allCases {
            let item = terminalItems[terminalChoice]
            item?.state = preferences.terminalChoice == terminalChoice ? .on : .off
            item?.isEnabled = isTerminalInstalled(terminalChoice)
            item?.toolTip = isTerminalInstalled(terminalChoice) ? nil : "Not installed"
        }

        for openMode in OpenMode.allCases {
            openModeItems[openMode]?.state = preferences.openMode == openMode ? .on : .off
        }
    }

    private func isTerminalInstalled(_ terminalChoice: TerminalChoice) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: terminalChoice.bundleIdentifier) != nil
    }

    @objc private func selectTerminal(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let terminalChoice = TerminalChoice.fromStoredValue(rawValue) else {
            return
        }

        SharedPreferences.shared.terminalChoice = terminalChoice
        refreshChecks()
    }

    @objc private func selectOpenMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let openMode = OpenMode(rawValue: rawValue) else {
            return
        }

        SharedPreferences.shared.openMode = openMode
        refreshChecks()
    }

    @objc private func openExtensionPreferences() {
        if #available(macOS 10.14, *) {
            FIFinderSyncController.showExtensionManagementInterface()
            return
        }

        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.extensions?FinderSync") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func showAbout() {
        aboutController.show()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
