on launchITerm2(targetPath, openMode)
	if openMode is "new_tab" then
		my launchITerm2NewTab(targetPath)
	else if openMode is "new_window" then
		my launchNewWindow("iTerm", targetPath)
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
