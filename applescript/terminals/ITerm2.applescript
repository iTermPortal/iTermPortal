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
