use scripting additions

property appTitle : "Open Terminal Here"

on run
	my ensureMenuBarHelperRunning()
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
