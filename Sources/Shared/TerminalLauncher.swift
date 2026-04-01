import AppKit
import Foundation

enum LaunchError: Error, LocalizedError {
    case appNotInstalled(String)
    case appleScriptFailed(String)

    var errorDescription: String? {
        switch self {
        case .appNotInstalled(let name):
            return "'\(name)' is not installed. Change your terminal in the iTermPortal menu bar icon."
        case .appleScriptFailed(let detail):
            return "Could not open a new tab: \(detail)"
        }
    }
}

protocol TerminalLaunching {
    func launch(path: URL, mode: OpenMode) throws
}

final class TerminalLauncher: TerminalLaunching {
    func launch(path: URL, mode: OpenMode) throws {
        let terminalURL = try applicationURL(for: .terminal)
        switch mode {
        case .newTerminal:
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.createsNewApplicationInstance = true
            open([path], withApplicationAt: terminalURL, configuration: configuration)
        case .newWindow:
            open([path], withApplicationAt: terminalURL, configuration: NSWorkspace.OpenConfiguration())
        case .newTab:
            do {
                try executeAppleScript("""
                tell application "Terminal"
                    activate
                    if (count of windows) = 0 then
                        do script "cd '\(path.path.shellEscaped)'"
                    else
                        do script "cd '\(path.path.shellEscaped)'" in front window
                    end if
                end tell
                """)
            } catch {
                let configuration = NSWorkspace.OpenConfiguration()
                configuration.createsNewApplicationInstance = false
                open([path], withApplicationAt: terminalURL, configuration: configuration)
            }
        }
    }
}

final class ITermLauncher: TerminalLaunching {
    func launch(path: URL, mode: OpenMode) throws {
        let appURL = try applicationURL(for: .iTerm2)
        switch mode {
        case .newTerminal:
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.createsNewApplicationInstance = true
            open([path], withApplicationAt: appURL, configuration: configuration)
        case .newWindow:
            open([path], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
        case .newTab:
            try executeAppleScript("""
            tell application "iTerm"
                activate
                if (count of windows) = 0 then
                    create window with default profile
                else
                    tell current window to create tab with default profile
                end if
                tell current session of current window
                    write text "cd '\(path.path.shellEscaped)'"
                end tell
            end tell
            """)
        }
    }
}

final class GhosttyLauncher: TerminalLaunching {
    func launch(path: URL, mode: OpenMode) throws {
        let appURL = try applicationURL(for: .ghostty)
        switch mode {
        case .newTerminal:
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.createsNewApplicationInstance = true
            configuration.arguments = ["--working-directory=\(path.path)"]
            openApplication(at: appURL, configuration: configuration)
        case .newWindow, .newTab:
            open([path], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
        }
    }
}

final class WarpLauncher: TerminalLaunching {
    func launch(path: URL, mode: OpenMode) throws {
        let appURL = try applicationURL(for: .warp)
        switch mode {
        case .newTerminal:
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.createsNewApplicationInstance = true
            open([path], withApplicationAt: appURL, configuration: configuration)
        case .newWindow:
            open([path], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
        case .newTab:
            guard let url = Self.makeNewTabURL(for: path), NSWorkspace.shared.open(url) else {
                throw LaunchError.appleScriptFailed("Warp could not handle the new tab request.")
            }
        }
    }

    static func makeNewTabURL(for path: URL) -> URL? {
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.remove(charactersIn: "/&+=?#")

        guard let encodedPath = path.path.addingPercentEncoding(withAllowedCharacters: allowedCharacters) else {
            return nil
        }

        return URL(string: "warp://action/new_tab?path=\(encodedPath)")
    }
}

enum TerminalLauncherFactory {
    static func launcher(for choice: TerminalChoice) -> TerminalLaunching {
        switch choice {
        case .terminal:
            return TerminalLauncher()
        case .iTerm2:
            return ITermLauncher()
        case .ghostty:
            return GhosttyLauncher()
        case .warp:
            return WarpLauncher()
        }
    }

    static func launch(path: URL) {
        let preferences = SharedPreferences.shared
        do {
            try launcher(for: preferences.terminalChoice).launch(path: path, mode: preferences.openMode)
        } catch LaunchError.appNotInstalled(let name) {
            showError("'\(name)' is not installed.")
        } catch {
            showError(error.localizedDescription)
        }
    }

    private static func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "iTermPortal"
            alert.informativeText = message
            alert.alertStyle = .warning
            NSApp?.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }
}

private func applicationURL(for terminal: TerminalChoice) throws -> URL {
    guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: terminal.bundleIdentifier) else {
        throw LaunchError.appNotInstalled(terminal.displayTitle)
    }
    return url
}

private func open(_ urls: [URL], withApplicationAt applicationURL: URL, configuration: NSWorkspace.OpenConfiguration) {
    NSWorkspace.shared.open(urls, withApplicationAt: applicationURL, configuration: configuration) { _, error in
        if let error {
            NSLog("iTermPortal failed to open %@: %@", applicationURL.path, error.localizedDescription)
        }
    }
}

private func openApplication(at applicationURL: URL, configuration: NSWorkspace.OpenConfiguration) {
    NSWorkspace.shared.openApplication(at: applicationURL, configuration: configuration) { _, error in
        if let error {
            NSLog("iTermPortal failed to open %@: %@", applicationURL.path, error.localizedDescription)
        }
    }
}

private func executeAppleScript(_ source: String) throws {
    var errorDictionary: NSDictionary?
    NSAppleScript(source: source)?.executeAndReturnError(&errorDictionary)
    if let errorDictionary {
        throw LaunchError.appleScriptFailed(errorDictionary.description)
    }
}
