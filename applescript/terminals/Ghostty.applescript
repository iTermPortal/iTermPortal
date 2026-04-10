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
	-- Ghostty's CLI actions do not IPC reliably into a running instance on macOS,
	-- and `open -a Ghostty <path>` gets routed to the existing window as a new tab.
	-- Forcing a new Ghostty process with --working-directory produces a fresh window
	-- at the requested path, which matches what the user expects from "new window".
	try
		do shell script "open -na Ghostty --args --working-directory=" & quoted form of targetPath
	on error
		my launchFallbackTerminal("Ghostty", targetPath, "new_window")
	end try
end launchGhosttyNewWindow

on launchGhosttyNewTab(targetPath)
	try
		do shell script "open -a Ghostty " & quoted form of targetPath
	on error
		my launchGhosttyNewTerminal(targetPath)
	end try
end launchGhosttyNewTab
