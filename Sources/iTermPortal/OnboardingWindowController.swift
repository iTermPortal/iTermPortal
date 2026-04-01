import AppKit
import FinderSync
import ServiceManagement

final class OnboardingWindowController: NSObject {
    static let shared = OnboardingWindowController()

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    private var window: NSWindow?

    func showIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding) else {
            return
        }

        show()
    }

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let panel = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        panel.title = "Welcome to iTermPortal"
        panel.center()
        panel.isReleasedWhenClosed = false

        let contentView = NSView()
        panel.contentView = contentView

        let titleLabel = NSTextField(labelWithString: "iTermPortal is ready")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 22)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let descriptionLabel = NSTextField(
            wrappingLabelWithString: """
            A Finder toolbar menu now comes from the bundled extension, and the menu bar app keeps your terminal choice in sync. If the Finder item is not visible yet, use Manage Extension to enable it in System Settings.
            """
        )
        descriptionLabel.font = NSFont.systemFont(ofSize: 13)
        descriptionLabel.textColor = .secondaryLabelColor
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        let bulletLabel = NSTextField(
            wrappingLabelWithString: """
            • Use the menu bar icon to pick Terminal, iTerm2, Ghostty, or Warp.
            • Choose whether folders open in a new terminal, window, or tab.
            • Enable launch at login so the menu bar controls are always ready.
            """
        )
        bulletLabel.font = NSFont.systemFont(ofSize: 13)
        bulletLabel.translatesAutoresizingMaskIntoConstraints = false

        let loginButton = NSButton(title: loginButtonTitle(), target: self, action: #selector(enableAtLogin))
        loginButton.bezelStyle = .rounded
        loginButton.translatesAutoresizingMaskIntoConstraints = false

        let extensionButton = NSButton(title: "Manage Extension", target: self, action: #selector(openExtensionPreferences))
        extensionButton.bezelStyle = .rounded
        extensionButton.translatesAutoresizingMaskIntoConstraints = false

        let doneButton = NSButton(title: "Done", target: self, action: #selector(finishOnboarding))
        doneButton.bezelStyle = .rounded
        doneButton.keyEquivalent = "\r"
        doneButton.translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, descriptionLabel, bulletLabel, loginButton, extensionButton, doneButton].forEach(contentView.addSubview)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            bulletLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 18),
            bulletLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            bulletLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            loginButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            extensionButton.leadingAnchor.constraint(equalTo: loginButton.trailingAnchor, constant: 12),
            extensionButton.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor),

            doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            doneButton.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor)
        ])

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = panel
    }

    private func loginButtonTitle() -> String {
        if #available(macOS 13.0, *) {
            return "Enable at Login"
        }
        return "Open Login Items"
    }

    @objc private func enableAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
            } catch {
                presentAlert(
                    title: "Could not enable login",
                    message: error.localizedDescription
                )
            }
            return
        }

        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.users?LoginItems") else {
            return
        }

        NSWorkspace.shared.open(url)
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

    @objc private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: Keys.hasCompletedOnboarding)
        window?.close()
        window = nil
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}
