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
