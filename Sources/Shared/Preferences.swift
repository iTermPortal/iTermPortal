import Foundation

enum TerminalChoice: String, CaseIterable {
    case terminal = "Terminal"
    case iTerm2 = "iTerm"
    case ghostty = "Ghostty"
    case warp = "Warp"

    static func fromStoredValue(_ rawValue: String) -> TerminalChoice? {
        switch rawValue {
        case TerminalChoice.iTerm2.rawValue, "iTerm2":
            return .iTerm2
        default:
            return TerminalChoice(rawValue: rawValue)
        }
    }

    var displayTitle: String {
        switch self {
        case .terminal:
            return "Terminal"
        case .iTerm2:
            return "iTerm2"
        case .ghostty:
            return "Ghostty"
        case .warp:
            return "Warp"
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .terminal:
            return "com.apple.Terminal"
        case .iTerm2:
            return "com.googlecode.iterm2"
        case .ghostty:
            return "com.mitchellh.ghostty"
        case .warp:
            return "dev.warp.Warp-Stable"
        }
    }
}

enum OpenMode: String, CaseIterable {
    case newTerminal = "new_terminal"
    case newWindow = "new_window"
    case newTab = "new_tab"

    var displayTitle: String {
        switch self {
        case .newTerminal:
            return "New Terminal"
        case .newWindow:
            return "New Window"
        case .newTab:
            return "New Tab"
        }
    }
}

final class SharedPreferences {
    enum Keys {
        static let terminalChoice = "terminalChoice"
        static let openMode = "openMode"
    }

    static let suiteName = "group.com.hjoncour.fPortal"
    static let shared = SharedPreferences()

    let defaults: UserDefaults

    init(userDefaults: UserDefaults = UserDefaults(suiteName: SharedPreferences.suiteName) ?? .standard) {
        self.defaults = userDefaults
    }

    var terminalChoice: TerminalChoice {
        get {
            let rawValue = defaults.string(forKey: Keys.terminalChoice) ?? ""
            return TerminalChoice.fromStoredValue(rawValue) ?? .terminal
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.terminalChoice)
        }
    }

    var openMode: OpenMode {
        get {
            let rawValue = defaults.string(forKey: Keys.openMode) ?? ""
            return OpenMode(rawValue: rawValue) ?? .newWindow
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.openMode)
        }
    }
}
