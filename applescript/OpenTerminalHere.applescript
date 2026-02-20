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
	try
		do shell script "open -na iTerm " & quoted form of targetPath
	on error
		my launchFallbackTerminal("iTerm", targetPath, "new_terminal")
	end try
end launchITerm2NewTerminal

on launchITerm2NewTab(targetPath)
	set cdCommand to "cd " & quoted form of targetPath
	try
		set isRunning to do shell script "pgrep -x iTerm2 > /dev/null 2>&1 && echo yes || echo no"
		if isRunning is "yes" then
			do shell script "open -a iTerm"
			delay 0.3
			tell application "System Events"
				tell process "iTerm2"
					set frontmost to true
					keystroke "t" using command down
				end tell
			end tell
			delay 0.4
			tell application "System Events"
				tell process "iTerm2"
					keystroke cdCommand
					key code 36
				end tell
			end tell
		else
			my launchITerm2NewTerminal(targetPath)
		end if
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
		end tell

		-- Create new tab via Cmd+T (locale-independent, requires Accessibility).
		set tabCreated to false
		try
			tell application "System Events"
				tell process "Terminal"
					set frontmost to true
					keystroke "t" using command down
				end tell
			end tell
			set tabCreated to true
		end try

		if tabCreated then
			delay 0.5
			tell application "System Events"
				tell process "Terminal"
					keystroke cdCommand
					key code 36 -- press Enter
				end tell
			end tell
		else
			-- System Events failed — likely missing Accessibility permissions.
			try
				display dialog "fPortal needs Accessibility permissions to open new tabs in Terminal." & return & return & "Go to System Settings > Privacy & Security > Accessibility, then add fPortal." buttons {"Open System Settings", "Use New Window"} default button "Open System Settings" with icon caution
				set userChoice to button returned of result
				if userChoice is "Open System Settings" then
					do shell script "open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility'"
				end if
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
		do shell script "open -na Ghostty --args --working-directory=" & quoted form of targetPath
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
		if application "Ghostty" is running then
			tell application "Ghostty" to activate
			delay 0.3
			set cdCommand to "cd " & quoted form of targetPath
			tell application "System Events"
				tell process "Ghostty"
					set frontmost to true
					keystroke "t" using command down
				end tell
			end tell
			delay 0.3
			tell application "System Events"
				tell process "Ghostty"
					keystroke cdCommand
					key code 36 -- press Enter
				end tell
			end tell
		else
			my launchGhosttyNewTerminal(targetPath)
		end if
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
