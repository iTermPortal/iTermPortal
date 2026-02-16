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
			return do shell script "dirname " & quoted form of selectedPath
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

on launchTerminal(targetPath)
	do shell script "open -a Terminal " & quoted form of targetPath
end launchTerminal
