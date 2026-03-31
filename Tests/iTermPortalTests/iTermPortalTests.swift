import XCTest

final class SharedPreferencesTests: XCTestCase {
    func testDefaults() {
        let defaults = makeDefaults()
        let preferences = SharedPreferences(userDefaults: defaults)

        XCTAssertEqual(preferences.terminalChoice, .terminal)
        XCTAssertEqual(preferences.openMode, .newWindow)
    }

    func testTerminalChoiceRoundTrip() {
        let defaults = makeDefaults()
        let preferences = SharedPreferences(userDefaults: defaults)

        for choice in TerminalChoice.allCases {
            preferences.terminalChoice = choice
            XCTAssertEqual(preferences.terminalChoice, choice)
        }
    }

    func testOpenModeRoundTrip() {
        let defaults = makeDefaults()
        let preferences = SharedPreferences(userDefaults: defaults)

        for mode in OpenMode.allCases {
            preferences.openMode = mode
            XCTAssertEqual(preferences.openMode, mode)
        }
    }
}

final class PreferenceMigrationTests: XCTestCase {
    func testMigrationReadsLegacyFiles() throws {
        let defaults = makeDefaults()
        let preferences = SharedPreferences(userDefaults: defaults)
        let tempDirectory = try makeLegacyDirectory()

        try "iTerm2\n".write(
            to: tempDirectory.appendingPathComponent("terminal_choice.txt"),
            atomically: true,
            encoding: .utf8
        )
        try "new_tab\n".write(
            to: tempDirectory.appendingPathComponent("open_mode.txt"),
            atomically: true,
            encoding: .utf8
        )

        PreferenceMigration.migrateIfNeeded(
            sharedPreferences: preferences,
            defaults: defaults,
            legacyBaseURL: tempDirectory
        )

        XCTAssertEqual(preferences.terminalChoice, .iTerm2)
        XCTAssertEqual(preferences.openMode, .newTab)
    }

    func testMigrationDoesNotOverrideExistingValues() throws {
        let defaults = makeDefaults()
        let preferences = SharedPreferences(userDefaults: defaults)
        let tempDirectory = try makeLegacyDirectory()

        preferences.terminalChoice = .warp
        preferences.openMode = .newWindow

        try "Terminal\n".write(
            to: tempDirectory.appendingPathComponent("terminal_choice.txt"),
            atomically: true,
            encoding: .utf8
        )

        PreferenceMigration.migrateIfNeeded(
            sharedPreferences: preferences,
            defaults: defaults,
            legacyBaseURL: tempDirectory
        )

        XCTAssertEqual(preferences.terminalChoice, .warp)
        XCTAssertEqual(preferences.openMode, .newWindow)
    }
}

final class StringExtensionsTests: XCTestCase {
    func testShellEscapedForPlainPath() {
        XCTAssertEqual("/tmp/project".shellEscaped, "/tmp/project")
    }

    func testShellEscapedForPathWithSpaces() {
        XCTAssertEqual("/tmp/My Folder".shellEscaped, "/tmp/My Folder")
    }

    func testShellEscapedForPathWithSingleQuote() {
        XCTAssertEqual("/tmp/O'Brien".shellEscaped, "/tmp/O'\\''Brien")
    }
}

final class TerminalLauncherFactoryTests: XCTestCase {
    func testFactoryReturnsExpectedLauncherTypes() {
        XCTAssertTrue(TerminalLauncherFactory.launcher(for: .terminal) is TerminalLauncher)
        XCTAssertTrue(TerminalLauncherFactory.launcher(for: .iTerm2) is ITermLauncher)
        XCTAssertTrue(TerminalLauncherFactory.launcher(for: .ghostty) is GhosttyLauncher)
        XCTAssertTrue(TerminalLauncherFactory.launcher(for: .warp) is WarpLauncher)
    }

    func testLaunchErrorDescriptionsAreNotEmpty() {
        XCTAssertFalse((LaunchError.appNotInstalled("Warp").errorDescription ?? "").isEmpty)
        XCTAssertFalse((LaunchError.appleScriptFailed("boom").errorDescription ?? "").isEmpty)
    }

    func testWarpNewTabURLEncoding() {
        let path = URL(fileURLWithPath: "/tmp/Project & Demo/O'Brien")
        let url = WarpLauncher.makeNewTabURL(for: path)

        XCTAssertEqual(
            url?.absoluteString,
            "warp://action/new_tab?path=%2Ftmp%2FProject%20%26%20Demo%2FO'Brien"
        )
    }
}

private func makeDefaults() -> UserDefaults {
    let suiteName = "tests.itermportal.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

private func makeLegacyDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}
