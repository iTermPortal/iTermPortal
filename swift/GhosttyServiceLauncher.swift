import AppKit
import Darwin
import Foundation

private enum LaunchMode: String {
    case newTab = "new-tab"
    case newWindow = "new-window"

    var serviceName: String {
        switch self {
        case .newTab:
            return "New Ghostty Tab Here"
        case .newWindow:
            return "New Ghostty Window Here"
        }
    }
}

private func fail(_ message: String) -> Never {
    let data = Data("iTermPortal Ghostty launcher: \(message)\n".utf8)
    FileHandle.standardError.write(data)
    exit(EXIT_FAILURE)
}

guard CommandLine.arguments.count == 3 else {
    fail("usage: GhosttyServiceLauncher <new-tab|new-window> <path>")
}

guard let mode = LaunchMode(rawValue: CommandLine.arguments[1]) else {
    fail("unknown launch mode: \(CommandLine.arguments[1])")
}

let requestedURL = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
var isDirectory: ObjCBool = false
guard FileManager.default.fileExists(atPath: requestedURL.path, isDirectory: &isDirectory) else {
    fail("path does not exist: \(requestedURL.path)")
}

let directoryPath = isDirectory.boolValue
    ? requestedURL.path
    : requestedURL.deletingLastPathComponent().path
let directoryURL = NSURL(fileURLWithPath: directoryPath, isDirectory: true)
let pasteboard = NSPasteboard(
    name: NSPasteboard.Name("com.hjoncour.fportal.ghostty.\(UUID().uuidString)")
)
defer { pasteboard.releaseGlobally() }

pasteboard.clearContents()
guard pasteboard.writeObjects([directoryURL]) else {
    fail("could not prepare the target folder")
}

guard NSPerformService(mode.serviceName, pasteboard) else {
    fail("Ghostty service is unavailable: \(mode.serviceName)")
}

// Services are dispatched asynchronously. Keep the helper alive long enough
// for Ghostty to read the temporary pasteboard and create the requested UI.
RunLoop.main.run(until: Date().addingTimeInterval(0.5))
