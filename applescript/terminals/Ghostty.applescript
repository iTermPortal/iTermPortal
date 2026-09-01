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
	-- Opening a folder through Launch Services follows Ghostty's configurable Dock
	-- drop behavior, whose default is a new tab. Use Ghostty's explicit macOS
	-- "New Ghostty Window Here" service so this mode always creates a window.
	try
		my launchGhosttyService("new-window", targetPath)
	on error
		-- Older Ghostty builds may not register the service. A separate app
		-- instance is the closest fallback that cannot target an existing tab.
		my launchGhosttyNewTerminal(targetPath)
	end try
end launchGhosttyNewWindow

on launchGhosttyService(serviceMode, targetPath)
	set appPath to POSIX path of (path to me)
	set helperPath to appPath & "Contents/MacOS/iTermPortalGhosttyService"
	set helperCommand to quoted form of helperPath & " " & quoted form of serviceMode & " " & quoted form of targetPath
	do shell script helperCommand
end launchGhosttyService

on launchGhosttyNewTab(targetPath)
	try
		do shell script "open -a Ghostty " & quoted form of targetPath
	on error
		my launchGhosttyNewTerminal(targetPath)
	end try
end launchGhosttyNewTab
