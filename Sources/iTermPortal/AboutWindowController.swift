import AppKit

final class AboutWindowController {
    private var window: NSWindow?

    func show() {
        if let existingWindow = window, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
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
        imageView.image = NSApp.applicationIconImage
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
