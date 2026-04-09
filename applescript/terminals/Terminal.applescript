on launchTerminalApp(targetPath, openMode)
	if openMode is "new_tab" then
		my launchTerminalAppNewTab(targetPath)
	else if openMode is "new_window" then
		my launchNewWindow("Terminal", targetPath)
	else
		my launchTerminalAppNewTerminal(targetPath)
	end if
end launchTerminalApp

on launchTerminalAppNewTerminal(targetPath)
	try
		do shell script "open -na Terminal " & quoted form of targetPath
	on error
		do shell script "open -a Terminal " & quoted form of targetPath
	end try
end launchTerminalAppNewTerminal

on launchTerminalAppNewTab(targetPath)
	set cdCommand to "cd " & quoted form of targetPath
	try
		tell application "Terminal"
			activate
			if (count of windows) is 0 then
				do script cdCommand
				return
			end if
		end tell

		-- Create new tab via Cmd+T (locale-independent, requires Accessibility).
		set tabCreated to false
		try
			tell application "System Events"
				tell process "Terminal"
					set frontmost to true
					keystroke "t" using command down
				end tell
			end tell
			set tabCreated to true
		end try

		if tabCreated then
			delay 0.3
			tell application "Terminal"
				do script cdCommand in front window
			end tell
		else
			my launchTerminalAppNewTerminal(targetPath)
		end if
	on error
		do shell script "open -a Terminal " & quoted form of targetPath
	end try
end launchTerminalAppNewTab
