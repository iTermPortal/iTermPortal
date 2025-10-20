# fPortal

A macOS menu bar app with Finder Sync extension for managing file synchronization.

## Features

- **Menu Bar Icon**: Access fPortal settings from the menu bar at the top of your screen
- **Finder Sync Extension**: Adds a terminal icon to Finder's toolbar for quick access
- **Settings Panel**: Configure sync options, notifications, and features
- **Badge Overlays**: Visual status indicators on files and folders
- **Context Menu Integration**: Quick actions available in Finder

## Setup Instructions

### 1. Build and Run
- Open `fPortal.xcodeproj` in Xcode
- Press `⌘R` to build and run the app

### 2. Menu Bar App
- After launching, you'll see a folder gear icon (⚙️📁) in your menu bar at the top of the screen
- Click the icon to open/close the settings window
- The app runs in the background (no Dock icon)

### 3. Enable Finder Sync Extension
- Open **System Settings** > **Privacy & Security** > **Extensions** > **Added Extensions**
- Enable **fPortalExtension**
- Open any Finder window in your home directory
- You should see the **terminal icon** appear in the Finder toolbar

### 4. Using the Finder Extension
- The **terminal icon** appears in the Finder toolbar when viewing directories in your home folder
- **Click the icon** to instantly open Terminal.app in the current directory
- No dropdown menu — direct action for quick access!

## Development

Run the setup script to create required directories:
```bash
./setup_extension.sh
```

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later