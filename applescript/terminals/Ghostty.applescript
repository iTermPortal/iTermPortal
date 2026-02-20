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
