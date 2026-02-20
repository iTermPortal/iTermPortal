-- GENERATED FILE: DO NOT EDIT DIRECTLY.
-- Edit '/Users/hjoncour/Projects/fPortal/applescript/OpenTerminalHere.base.applescript' and files under 'applescript/terminals/'.

use scripting additions

property appTitle : "Open Terminal Here"

on run
	my openTerminalForFinderContext(missing value)
end run

on reopen
	my openTerminalForFinderContext(missing value)
end reopen

on open inputItems
	my openTerminalForFinderContext(inputItems)
end open

on openTerminalForFinderContext(inputItems)
	try
		my ensureMenuBarHelperRunning()
		set targetPath to my resolveTargetPath(inputItems)
		if targetPath is missing value or targetPath is "" then error "Could not resolve a Finder folder."
		my launchTerminal(targetPath)
	on error errMsg
		display alert appTitle message errMsg as critical
	end try
end openTerminalForFinderContext

on resolveTargetPath(inputItems)
	try
		return my resolvePathFromFinder()
	on error
		set pathFromOpenEvent to my pathFromInputItems(inputItems)
		if pathFromOpenEvent is not missing value then return pathFromOpenEvent
		error "Open a Finder window and try again."
	end try
end resolveTargetPath

on resolvePathFromFinder()
	tell application "Finder"
		if not (exists Finder window 1) then error "Open a Finder window and try again."

		set selectedItems to selection as alias list
		if (count of selectedItems) > 0 then
			set firstSelection to item 1 of selectedItems
			set selectedPath to POSIX path of firstSelection
			return my directoryForPath(selectedPath)
		end if

		set currentTarget to (target of front Finder window) as alias
		return POSIX path of currentTarget
	end tell
end resolvePathFromFinder

on pathFromInputItems(inputItems)
	if inputItems is missing value then return missing value
	if (count of inputItems) is 0 then return missing value

	try
		set firstAlias to item 1 of inputItems as alias
		return my directoryForPath(POSIX path of firstAlias)
	on error
		return missing value
	end try
end pathFromInputItems

on directoryForPath(candidatePath)
	if candidatePath is "" then error "Finder returned an empty path."

	set quotedPath to quoted form of candidatePath
	set checkResult to do shell script "if [ -d " & quotedPath & " ]; then echo dir; else echo file; fi"
	if checkResult is "dir" then return candidatePath
	return do shell script "dirname " & quotedPath
end directoryForPath

on ensureMenuBarHelperRunning()
	try
		set mePath to POSIX path of (path to me)
		set helperPath to mePath & "Contents/Library/LoginItems/fPortalMenu.app"
		do shell script "if [ -d " & quoted form of helperPath & " ]; then open -gj " & quoted form of helperPath & "; fi"
	end try
end ensureMenuBarHelperRunning

on resolvePreferredTerminal()
	try
		set settingsPath to POSIX path of (path to home folder) & "Library/Application Support/fPortal/terminal_choice.txt"
		set preferredTerminal to do shell script "if [ -f " & quoted form of settingsPath & " ]; then /usr/bin/head -n 1 " & quoted form of settingsPath & "; fi"
		if preferredTerminal is not "" then return preferredTerminal
	on error
		-- Fallback below.
	end try
	return "Terminal"
end resolvePreferredTerminal

on resolveOpenMode()
	try
		set settingsPath to POSIX path of (path to home folder) & "Library/Application Support/fPortal/open_mode.txt"
		set openMode to do shell script "if [ -f " & quoted form of settingsPath & " ]; then /usr/bin/head -n 1 " & quoted form of settingsPath & "; fi"
		if openMode is "new_tab" then return "new_tab"
	on error
		-- Fallback below.
	end try
	return "new_terminal"
end resolveOpenMode

on launchTerminal(targetPath)
	set preferredTerminal to my resolvePreferredTerminal()
	set openMode to my resolveOpenMode()

	if preferredTerminal is "iTerm" or preferredTerminal is "iTerm2" then
		my launchITerm2(targetPath, openMode)
		return
	end if

	if preferredTerminal is "Terminal" then
		my launchTerminalApp(targetPath, openMode)
		return
	end if

	if preferredTerminal is "Ghostty" then
		my launchGhostty(targetPath, openMode)
		return
	end if

	if preferredTerminal is "Warp" then
		my launchWarp(targetPath, openMode)
		return
	end if

	my launchFallbackTerminal(preferredTerminal, targetPath, openMode)
end launchTerminal

on launchFallbackTerminal(preferredTerminal, targetPath, openMode)
	try
		if openMode is "new_terminal" then
			do shell script "open -na " & quoted form of preferredTerminal & " " & quoted form of targetPath
		else
			do shell script "open -a " & quoted form of preferredTerminal & " " & quoted form of targetPath
		end if
	on error
		do shell script "open -a Terminal " & quoted form of targetPath
	end try
end launchFallbackTerminal

-- >>> ITerm2.applescript
on launchITerm2(targetPath, openMode)
	if openMode is "new_tab" then
		my launchITerm2NewTab(targetPath)
	else
		my launchITerm2NewTerminal(targetPath)
	end if
end launchITerm2

on launchITerm2NewTerminal(targetPath)
	set cdCommand to "cd " & quoted form of targetPath
	try
		tell application id "com.googlecode.iterm2"
			activate
			set newWindow to (create window with default profile)
			tell current session of newWindow
				write text cdCommand
			end tell
		end tell
	on error
		try
			do shell script "open -na iTerm " & quoted form of targetPath
		on error
			my launchFallbackTerminal("iTerm", targetPath, "new_terminal")
		end try
	end try
end launchITerm2NewTerminal

on launchITerm2NewTab(targetPath)
	set cdCommand to "cd " & quoted form of targetPath
	try
		tell application id "com.googlecode.iterm2"
			activate
			if (count of windows) is 0 then
				set newWindow to (create window with default profile)
				tell current session of newWindow
					write text cdCommand
				end tell
			else
				tell current window
					create tab with default profile
					tell current session of current tab
						write text cdCommand
					end tell
				end tell
			end if
		end tell
	on error
		my launchFallbackTerminal("iTerm", targetPath, "new_tab")
	end try
end launchITerm2NewTab

-- >>> Terminal.applescript
on launchTerminalApp(targetPath, openMode)
	if openMode is "new_tab" then
		my launchTerminalAppNewTab(targetPath)
	else
		my launchTerminalAppNewTerminal(targetPath)
	end if
end launchTerminalApp

on launchTerminalAppNewTerminal(targetPath)
	try
		do shell script "open -na Terminal " & quoted form of targetPath
	on error
		do shell script "open -a Terminal " & quoted form of targetPath
	end try
end launchTerminalAppNewTerminal

on launchTerminalAppNewTab(targetPath)
	set cdCommand to "cd " & quoted form of targetPath
	try
		tell application "Terminal"
			activate
			if (count of windows) is 0 then
				do script cdCommand
				return
			end if
			set targetWindow to front window
			set originalTabCount to (count of tabs of targetWindow)
		end tell

		-- Force New Tab via UI scripting.
		set createdTab to false
		try
			tell application "System Events"
				tell process "Terminal"
					set frontmost to true
					click menu item "New Tab" of menu "Shell" of menu bar 1
				end tell
			end tell
			delay 0.1
			tell application "Terminal"
				if (count of tabs of targetWindow) > originalTabCount then
					set createdTab to true
					do script cdCommand in selected tab of targetWindow
					return
				end if
			end tell
		end try

		-- Retry with keyboard shortcut, then fall back to new window.
		if createdTab is false then
			try
				tell application "System Events"
					tell process "Terminal"
						set frontmost to true
						keystroke "t" using command down
					end tell
				end tell
				delay 0.1
				tell application "Terminal"
					if (count of tabs of targetWindow) > originalTabCount then
						do script cdCommand in selected tab of targetWindow
						return
					end if
				end tell
			end try

			my launchTerminalAppNewTerminal(targetPath)
		end if
	on error
		do shell script "open -a Terminal " & quoted form of targetPath
	end try
end launchTerminalAppNewTab

-- >>> Ghostty.applescript
on launchGhostty(targetPath, openMode)
	if openMode is "new_tab" then
		my launchGhosttyNewTab(targetPath)
	else
		my launchGhosttyNewTerminal(targetPath)
	end if
end launchGhostty

on launchGhosttyNewTerminal(targetPath)
	try
		do shell script "open -na Ghostty --args --gtk-single-instance=false --window-inherit-working-directory=false --working-directory=" & quoted form of targetPath
	on error
		try
			do shell script "open -na Ghostty " & quoted form of targetPath
		on error
			my launchFallbackTerminal("Ghostty", targetPath, "new_terminal")
		end try
	end try
end launchGhosttyNewTerminal

on launchGhosttyNewTab(targetPath)
	try
		do shell script "open -a Ghostty " & quoted form of targetPath
	on error
		my launchGhosttyNewTerminal(targetPath)
	end try
end launchGhosttyNewTab

-- >>> Warp.applescript
on launchWarp(targetPath, openMode)
	if openMode is "new_tab" then
		my launchWarpNewTab(targetPath)
	else
		my launchWarpNewTerminal(targetPath)
	end if
end launchWarp

on launchWarpNewTerminal(targetPath)
	try
		do shell script "open -na Warp " & quoted form of targetPath
	on error
		my launchFallbackTerminal("Warp", targetPath, "new_terminal")
	end try
end launchWarpNewTerminal

on launchWarpNewTab(targetPath)
	try
		do shell script "open -a Warp " & quoted form of targetPath
	on error
		my launchWarpNewTerminal(targetPath)
	end try
end launchWarpNewTab
