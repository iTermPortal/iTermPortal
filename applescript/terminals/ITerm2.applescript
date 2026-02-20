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
