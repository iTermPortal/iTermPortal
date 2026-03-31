import Cocoa
import FinderSync

@objc(FinderSync)
final class FinderSync: FIFinderSync {
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override var toolbarItemName: String {
        "Open in Terminal"
    }

    override var toolbarItemToolTip: String {
        "Open in \(SharedPreferences.shared.terminalChoice.displayTitle)"
    }

    override var toolbarItemImage: NSImage {
        NSImage(systemSymbolName: "terminal", accessibilityDescription: "Open in Terminal")!
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")

        if menuKind == .toolbarItemMenu {
            let openItem = NSMenuItem(
                title: "Open in \(SharedPreferences.shared.terminalChoice.displayTitle)",
                action: #selector(openTerminalHere(_:)),
                keyEquivalent: ""
            )
            openItem.target = self
            menu.addItem(openItem)
        }

        return menu
    }

    @IBAction func openTerminalHere(_ sender: AnyObject?) {
        guard let directoryURL = resolveDirectoryURL() else {
            showError("No Finder folder is targeted. Open a Finder window and try again.")
            return
        }

        TerminalLauncherFactory.launch(path: directoryURL)
    }

    override func beginObservingDirectory(at url: URL) {}

    override func endObservingDirectory(at url: URL) {}

    private func resolveDirectoryURL() -> URL? {
        if let selectedURL = FIFinderSyncController.default().selectedItemURLs()?.first {
            return resolveDirectory(from: selectedURL)
        }

        if let targetedURL = FIFinderSyncController.default().targetedURL() {
            return resolveDirectory(from: targetedURL)
        }

        return nil
    }

    private func resolveDirectory(from url: URL) -> URL {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return url
        }

        return url.deletingLastPathComponent()
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "iTermPortal"
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
}
