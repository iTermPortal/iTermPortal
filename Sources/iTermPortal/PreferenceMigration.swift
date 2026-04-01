import Foundation

enum PreferenceMigration {
    static func migrateIfNeeded(
        sharedPreferences: SharedPreferences = .shared,
        defaults: UserDefaults? = UserDefaults(suiteName: SharedPreferences.suiteName),
        legacyBaseURL: URL? = nil
    ) {
        guard defaults?.object(forKey: SharedPreferences.Keys.terminalChoice) == nil else {
            return
        }

        let baseURL = legacyBaseURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("iTermPortal", isDirectory: true)

        let terminalChoiceURL = baseURL.appendingPathComponent("terminal_choice.txt", isDirectory: false)
        let openModeURL = baseURL.appendingPathComponent("open_mode.txt", isDirectory: false)

        if let rawValue = readTrimmedString(from: terminalChoiceURL),
           let terminalChoice = TerminalChoice.fromStoredValue(rawValue) {
            sharedPreferences.terminalChoice = terminalChoice
        }

        if let rawValue = readTrimmedString(from: openModeURL),
           let openMode = OpenMode(rawValue: rawValue) {
            sharedPreferences.openMode = openMode
        }
    }

    private static func readTrimmedString(from url: URL) -> String? {
        guard let value = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
