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
		do shell script "open -a Ghostty " & quoted form of targetPath
	on error
		my launchGhosttyNewTerminal(targetPath)
	end try
end launchGhosttyNewTab
