import Cocoa
import FinderSync
import OSLog

@objc(FinderSync)
final class FinderSync: FIFinderSync {
    private let logger = Logger(subsystem: "com.hjoncour.fPortal", category: "FinderSync")

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
        logger.info("Finder Sync initialized")
    }

    override var toolbarItemName: String {
        logger.debug("toolbarItemName requested")
        return "Open in Terminal"
    }

    override var toolbarItemToolTip: String {
        let tooltip = "Open in \(SharedPreferences.shared.terminalChoice.displayTitle)"
        logger.debug("toolbarItemToolTip requested: \(tooltip, privacy: .public)")
        return tooltip
    }

    override var toolbarItemImage: NSImage {
        logger.debug("toolbarItemImage requested")
        return NSImage(systemSymbolName: "terminal", accessibilityDescription: "Open in Terminal")!
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        logger.info("menu requested for kind \(menuKind.rawValue)")
        let menu = NSMenu(title: "")

        if menuKind == .toolbarItemMenu || menuKind == .contextualMenuForContainer || menuKind == .contextualMenuForItems {
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
        logger.info("openTerminalHere invoked")
        guard let directoryURL = resolveDirectoryURL() else {
            logger.error("Could not resolve a Finder folder")
            showError("No Finder folder is targeted. Open a Finder window and try again.")
            return
        }

        logger.info("Launching terminal for \(directoryURL.path, privacy: .public)")
        TerminalLauncherFactory.launch(path: directoryURL)
    }

    override func beginObservingDirectory(at url: URL) {}

    override func endObservingDirectory(at url: URL) {}

    private func resolveDirectoryURL() -> URL? {
        if let selectedURL = FIFinderSyncController.default().selectedItemURLs()?.first {
            logger.info("Using selected item URL \(selectedURL.path, privacy: .public)")
            return resolveDirectory(from: selectedURL)
        }

        if let targetedURL = FIFinderSyncController.default().targetedURL() {
            logger.info("Using targeted URL \(targetedURL.path, privacy: .public)")
            return resolveDirectory(from: targetedURL)
        }

        if let finderURL = resolveDirectoryFromFinder() {
            logger.info("Using Finder AppleScript fallback \(finderURL.path, privacy: .public)")
            return finderURL
        }

        logger.error("No selectedItemURLs, targetedURL, or Finder fallback path")
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
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    private func resolveDirectoryFromFinder() -> URL? {
        let script = """
        tell application "Finder"
            if not (exists Finder window 1) then return ""

            set selectedItems to selection as alias list
            if (count of selectedItems) > 0 then
                set firstSelection to item 1 of selectedItems
                return POSIX path of firstSelection
            end if

            return POSIX path of ((target of front Finder window) as alias)
        end tell
        """

        var errorDictionary: NSDictionary?
        guard let appleScript = NSAppleScript(source: script),
              let result = appleScript.executeAndReturnError(&errorDictionary).stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !result.isEmpty else {
            if let errorDictionary {
                logger.error("Finder AppleScript fallback failed: \(errorDictionary.description, privacy: .public)")
            }
            return nil
        }

        return resolveDirectory(from: URL(fileURLWithPath: result))
    }
}
