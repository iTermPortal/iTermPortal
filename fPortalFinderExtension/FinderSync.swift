import Cocoa
import FinderSync

// Shared constants for app group and key
private let appGroupId = "group.com.hjoncour.fPortal"
private let preferredBundleKey = "preferredBundleID"

// Finder Sync lifecycle:
// - Finder launches the extension process on demand.
// - directoryURLs determines where the extension is active.
// - Toolbar button and contextual menu are provided by FIFinderSync.
@objc(FinderSync)
final class FinderSync: FIFinderSync {

	override init() {
		super.init()
		let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
		FIFinderSyncController.default().directoryURLs = Set([home])
		NSLog("OpenInAppFinderExtension initialized. Monitoring %@", home.path)
	}

	// Toolbar configuration
	override var toolbarItemName: String { "Code" }

	override var toolbarItemToolTip: String {
		"Open the selection or current folder in your preferred editor"
	}

	override var toolbarItemImage: NSImage {
		if let image = NSImage(named: "CodeTemplate") {
			image.isTemplate = true
			return image
		}
		if let symbol = NSImage(
			systemSymbolName: "chevron.left.slash.chevron.right",
			accessibilityDescription: "Code"
		) {
			symbol.isTemplate = true
			return symbol
		}
		// Fallback: empty template image
		let fallback = NSImage(size: NSSize(width: 18, height: 18))
		fallback.isTemplate = true
		return fallback
	}

	// Contextual menu for Finder
	override func menu(for menuKind: FIMenuKind) -> NSMenu? {
		let menu = NSMenu(title: "OpenInApp")

		// Primary action always reads the preferred bundle id (default: VS Code)
		let primary = NSMenuItem(
			title: "Open in Visual Studio Code",
			action: #selector(openInPreferredApp(_:)),
			keyEquivalent: ""
		)
		primary.target = self
		menu.addItem(primary)

		menu.addItem(.separator())

		let openWith = NSMenuItem(title: "Open With…", action: nil, keyEquivalent: "")
		let sub = NSMenu(title: "Open With…")

		let vs = NSMenuItem(title: "Visual Studio Code", action: #selector(openVSCode(_:)), keyEquivalent: "")
		vs.target = self
		sub.addItem(vs)

		let term = NSMenuItem(title: "Terminal", action: #selector(openTerminal(_:)), keyEquivalent: "")
		term.target = self
		sub.addItem(term)

		let iterm = NSMenuItem(title: "iTerm", action: #selector(openITerm(_:)), keyEquivalent: "")
		iterm.target = self
		sub.addItem(iterm)

		openWith.submenu = sub
		menu.addItem(openWith)

		return menu
	}

	@objc private func openInPreferredApp(_ sender: Any?) {
		open(usingBundleID: preferredBundleID())
	}

	@objc private func openVSCode(_ sender: Any?) {
		open(usingBundleID: "com.microsoft.VSCode")
	}

	@objc private func openTerminal(_ sender: Any?) {
		open(usingBundleID: "com.apple.Terminal")
	}

	@objc private func openITerm(_ sender: Any?) {
		open(usingBundleID: "com.googlecode.iterm2")
	}

	private func preferredBundleID() -> String {
		let defaults = UserDefaults(suiteName: appGroupId)
		let bundleID = defaults?.string(forKey: preferredBundleKey) ?? "com.microsoft.VSCode"
		return bundleID.isEmpty ? "com.microsoft.VSCode" : bundleID
	}

	// Resolve selected items, or fall back to the targeted folder (frontmost Finder window)
	private func resolvedTargetURLs() -> [URL] {
		let controller = FIFinderSyncController.default()

		if let selection = controller.selectedItemURLs(), !selection.isEmpty {
			return selection
		}
		if let targeted = controller.targetedURL() {
			return [targeted]
		}
		return []
	}

	// Open the resolved URLs in the given application bundle id.
	private func open(usingBundleID bundleID: String) {
		let urls = resolvedTargetURLs()
		guard !urls.isEmpty else {
			NSLog("OpenInAppFinderExtension: No selection or targeted folder; doing nothing.")
			return
		}

		// Preferred path: open via NSWorkspace with the specific application URL.
		if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
			let config = NSWorkspace.OpenConfiguration()
			config.activates = true
			NSWorkspace.shared.open(urls, withApplicationAt: appURL, configuration: config) { _, error in
				if let error = error {
					NSLog("OpenInAppFinderExtension: open() failed with error: %@", String(describing: error))
				}
			}
			return
		}

		// Fallback: use /usr/bin/open -b <bundleID> <paths...>
		do {
			let proc = Process()
			proc.executableURL = URL(fileURLWithPath: "/usr/bin/open")
			proc.arguments = ["-b", bundleID] + urls.map { $0.path }
			try proc.run()
		} catch {
			NSLog("OpenInAppFinderExtension: fallback open failed for bundle id %@, error: %@", bundleID, String(describing: error))
		}
	}
}


