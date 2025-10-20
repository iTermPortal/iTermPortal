//
//  FinderSync.swift
//  fPortalExtension
//
//  Created by Hugo Joncour on 2025-10-19.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    
    override init() {
        super.init()
        
        NSLog("FinderSync() launched from %@", Bundle.main.bundlePath as NSString)
        
        // Monitor all directories - user's home directory and common locations
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        FIFinderSyncController.default().directoryURLs = [homeURL]
        
        // Set up images for our badge identifiers
        FIFinderSyncController.default().setBadgeImage(NSImage(named: NSImage.colorPanelName)!, label: "Status One" , forBadgeIdentifier: "One")
        FIFinderSyncController.default().setBadgeImage(NSImage(named: NSImage.cautionName)!, label: "Status Two", forBadgeIdentifier: "Two")
    }
    
    // MARK: - Primary Finder Sync protocol methods
    
    override func beginObservingDirectory(at url: URL) {
        // The user is now seeing the container's contents.
        // If they see it in more than one view at a time, we're only told once.
        NSLog("beginObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    
    override func endObservingDirectory(at url: URL) {
        // The user is no longer seeing the container's contents.
        NSLog("endObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    override func requestBadgeIdentifier(for url: URL) {
        NSLog("requestBadgeIdentifierForURL: %@", url.path as NSString)
        
        // For demonstration purposes, this picks one of our two badges, or no badge at all, based on the filename.
        let whichBadge = abs(url.path.hash) % 3
        let badgeIdentifier = ["", "One", "Two"][whichBadge]
        FIFinderSyncController.default().setBadgeIdentifier(badgeIdentifier, for: url)
    }
    
    // MARK: - Menu and toolbar item support
    
    override var toolbarItemName: String {
        return "fPortal"
    }
    
    override var toolbarItemToolTip: String {
        return "fPortal — Open Terminal here"
    }
    
    override var toolbarItemImage: NSImage {
        // Use SF Symbol for terminal icon
        if let terminalImage = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: "fPortal") {
            return terminalImage
        }
        // Fallback to computer icon if terminal not available
        return NSImage(systemSymbolName: "laptopcomputer", accessibilityDescription: "fPortal") ?? NSImage(named: NSImage.computerName)!
    }
    
    // MARK: - Toolbar button action
    
    // Override to handle toolbar item clicks directly (no menu)
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        // When user clicks the toolbar icon, this is called
        // We open Terminal immediately instead of showing a menu
        openTerminalInCurrentDirectory()
        
        // Return nil to not show any menu
        return nil
    }
    
    private func openTerminalInCurrentDirectory() {
        guard let target = FIFinderSyncController.default().targetedURL() else {
            NSLog("No target URL available")
            return
        }
        
        let path = target.path
        NSLog("Opening Terminal at: %@", path as NSString)
        
        // Use AppleScript to open Terminal at the specified directory
        let script = """
        tell application "Terminal"
            activate
            do script "cd '\(path.replacingOccurrences(of: "'", with: "'\\''"))'"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                NSLog("AppleScript error: %@", error)
            }
        }
    }
}
