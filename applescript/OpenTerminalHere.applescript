-- GENERATED FILE: DO NOT EDIT DIRECTLY.
-- Edit 'applescript/OpenTerminalHere.base.applescript' and files under 'applescript/terminals/'.

use scripting additions

property appTitle : "Open Terminal Here"

on run
	my ensureMenuBarHelperRunning()
	my openTerminalForFinderContext(missing value)
end run

on reopen
	my openTerminalForFinderContext(missing value)
end reopen

on open inputItems
	my openTerminalForFinderContext(inputItems)
end open

on openTerminalForFinderContext(inputItems)
	my ensureMenuBarHelperRunning()
	try
		set targetPath to my resolveTargetPath(inputItems)
		if targetPath is missing value or targetPath is "" then return
		my launchTerminal(targetPath)
	on error
		return
	end try
end openTerminalForFinderContext

on resolveTargetPath(inputItems)
	set pathFromOpenEvent to my pathFromInputItems(inputItems)
	if pathFromOpenEvent is not missing value then return pathFromOpenEvent

	try
		return my resolvePathFromFinder()
	on error
		error "Open a Finder window and try again."
	end try
end resolveTargetPath

on resolvePathFromFinder()
	tell application "Finder"
		if not (exists window 1) then error "Open a Finder window and try again."

		set selectedItems to selection
		if (count of selectedItems) > 0 then
			set firstSelection to item 1 of selectedItems
			set selectedPath to POSIX path of (firstSelection as alias)
			set resolvedSelection to my directoryForSelection(selectedPath)
			if resolvedSelection is not missing value then return resolvedSelection
		end if

		set currentTarget to (target of front window) as alias
		return POSIX path of currentTarget
	end tell
end resolvePathFromFinder

on directoryForSelection(candidatePath)
	if candidatePath is "" then return missing value
	if my isBundlePath(candidatePath) then return missing value
	return my directoryForPath(candidatePath)
end directoryForSelection

on isBundlePath(candidatePath)
	set trimmedPath to candidatePath
	if trimmedPath ends with "/" then set trimmedPath to text 1 thru -2 of trimmedPath
	set bundleSuffixes to {".app", ".bundle", ".framework", ".pkg", ".plugin", ".kext", ".xpc", ".appex"}
	repeat with suffix in bundleSuffixes
		if trimmedPath ends with suffix then return true
	end repeat
	return false
end isBundlePath

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
		set helperPath to mePath & "Contents/Library/LoginItems/iTermPortalMenu.app"
		do shell script "if [ -d " & quoted form of helperPath & " ]; then open -gj " & quoted form of helperPath & "; fi"
	end try
end ensureMenuBarHelperRunning

on resolvePreferredTerminal()
	try
		set settingsPath to POSIX path of (path to home folder) & "Library/Application Support/iTermPortal/terminal_choice.txt"
		set preferredTerminal to do shell script "if [ -f " & quoted form of settingsPath & " ]; then /usr/bin/head -n 1 " & quoted form of settingsPath & "; fi"
		if preferredTerminal is not "" then return preferredTerminal
	on error
		-- Fallback below.
	end try
	return "Terminal"
end resolvePreferredTerminal

on resolveOpenMode()
	try
		set settingsPath to POSIX path of (path to home folder) & "Library/Application Support/iTermPortal/open_mode.txt"
		set openMode to do shell script "if [ -f " & quoted form of settingsPath & " ]; then /usr/bin/head -n 1 " & quoted form of settingsPath & "; fi"
		if openMode is "new_terminal" then return "new_terminal"
		if openMode is "new_window" then return "new_window"
		if openMode is "new_tab" then return "new_tab"
	on error
		-- Fallback below.
	end try
	return "new_window"
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

on launchNewWindow(appName, targetPath)
	try
		do shell script "open -a " & quoted form of appName & " " & quoted form of targetPath
	on error
		my launchFallbackTerminal(appName, targetPath, "new_window")
	end try
end launchNewWindow

-- >>> ITerm2.applescript
on launchITerm2(targetPath, openMode)
	if openMode is "new_tab" then
		my launchITerm2NewTab(targetPath)
	else if openMode is "new_window" then
		my launchITerm2NewWindow(targetPath)
	else
		my launchITerm2NewTerminal(targetPath)
	end if
end launchITerm2

on launchITerm2NewTerminal(targetPath)
	-- Best-effort: ask macOS to launch a brand new iTerm2 instance.
	-- iTerm2 ignores this unless "Allow multiple instances" is enabled in its settings,
	-- in which case a second process starts. We then drive the frontmost instance
	-- to create a window cd'd into the target directory.
	try
		do shell script "open -n -a iTerm"
		delay 0.5
	end try
	my launchITerm2NewWindow(targetPath)
end launchITerm2NewTerminal

on launchITerm2NewWindow(targetPath)
	set cdCommand to "cd " & quoted form of targetPath
	try
		set scriptSource to "tell application \"iTerm\"" & return & ¬
			"activate" & return & ¬
			"set newWindow to (create window with default profile)" & return & ¬
			"tell current session of newWindow" & return & ¬
			"write text " & quote & cdCommand & quote & return & ¬
			"end tell" & return & ¬
			"end tell"
		run script scriptSource
	on error
		my launchFallbackTerminal("iTerm", targetPath, "new_window")
	end try
end launchITerm2NewWindow

on launchITerm2NewTab(targetPath)
	set cdCommand to "cd " & quoted form of targetPath
	try
		set scriptSource to "tell application \"iTerm\"" & return & ¬
			"activate" & return & ¬
			"if (count of windows) = 0 then" & return & ¬
			"create window with default profile" & return & ¬
			"else" & return & ¬
			"tell current window" & return & ¬
			"create tab with default profile" & return & ¬
			"end tell" & return & ¬
			"end if" & return & ¬
			"tell current session of current window" & return & ¬
			"write text " & quote & cdCommand & quote & return & ¬
			"end tell" & return & ¬
			"end tell"
		run script scriptSource
	on error
		my launchFallbackTerminal("iTerm", targetPath, "new_tab")
	end try
end launchITerm2NewTab

-- >>> Terminal.applescript
on launchTerminalApp(targetPath, openMode)
	if openMode is "new_tab" then
		my launchTerminalAppNewTab(targetPath)
	else if openMode is "new_window" then
		my launchTerminalAppNewWindow(targetPath)
	else
		my launchTerminalAppNewTerminal(targetPath)
	end if
end launchTerminalApp

on launchTerminalAppNewWindow(targetPath)
	set cdCommand to "cd " & quoted form of targetPath
	try
		tell application "Terminal"
			activate
			do script cdCommand
		end tell
	on error
		do shell script "open -a Terminal " & quoted form of targetPath
	end try
end launchTerminalAppNewWindow

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
			delay 0.3
			tell application "Terminal"
				do script cdCommand in front window
			end tell
		else
			my launchTerminalAppNewWindow(targetPath)
		end if
	on error
		my launchTerminalAppNewWindow(targetPath)
	end try
end launchTerminalAppNewTab

-- >>> Ghostty.applescript
on launchGhostty(targetPath, openMode)
	if openMode is "new_tab" then
		my launchGhosttyNewTab(targetPath)
	else if openMode is "new_window" then
		my launchGhosttyNewWindow(targetPath)
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

on launchGhosttyNewWindow(targetPath)
	try
		set ghosttyBundle to do shell script "mdfind \"kMDItemCFBundleIdentifier == 'com.mitchellh.ghostty'\" | head -n 1"
		if ghosttyBundle is "" then error "Ghostty bundle not found"
		set ghosttyBin to ghosttyBundle & "/Contents/MacOS/ghostty"
		do shell script quoted form of ghosttyBin & " +new-window --working-directory=" & quoted form of targetPath & " > /dev/null 2>&1 &"
	on error
		my launchGhosttyNewTerminal(targetPath)
	end try
end launchGhosttyNewWindow

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
	else if openMode is "new_window" then
		my launchWarpNewWindow(targetPath)
	else
		my launchWarpNewTerminal(targetPath)
	end if
end launchWarp

on launchWarpNewTerminal(targetPath)
	try
		do shell script "open -na Warp " & quoted form of targetPath
	on error
		my launchWarpNewWindow(targetPath)
	end try
end launchWarpNewTerminal

on launchWarpNewWindow(targetPath)
	try
		set encodedPath to my urlEncodePath(targetPath)
		do shell script "open 'warp://action/new_window?path=" & encodedPath & "'"
	on error
		my launchFallbackTerminal("Warp", targetPath, "new_window")
	end try
end launchWarpNewWindow

on launchWarpNewTab(targetPath)
	try
		set encodedPath to my urlEncodePath(targetPath)
		do shell script "open 'warp://action/new_tab?path=" & encodedPath & "'"
	on error
		my launchWarpNewWindow(targetPath)
	end try
end launchWarpNewTab

on urlEncodePath(targetPath)
	return do shell script "python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' " & quoted form of targetPath
end urlEncodePath
