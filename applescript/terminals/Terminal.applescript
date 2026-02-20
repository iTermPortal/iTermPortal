on launchTerminalApp(targetPath, openMode)
	if openMode is "new_tab" then
		my launchTerminalAppNewTab(targetPath)
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
			set targetWindow to front window
			set originalTabCount to (count of tabs of targetWindow)
		end tell

		-- Force New Tab via UI scripting.
		set createdTab to false
		try
			tell application "System Events"
				tell process "Terminal"
					set frontmost to true
					click menu item "New Tab" of menu "Shell" of menu bar 1
				end tell
			end tell
			delay 0.1
			tell application "Terminal"
				if (count of tabs of targetWindow) > originalTabCount then
					set createdTab to true
					do script cdCommand in selected tab of targetWindow
					return
				end if
			end tell
		end try

		-- Retry with keyboard shortcut, then fall back to new window.
		if createdTab is false then
			try
				tell application "System Events"
					tell process "Terminal"
						set frontmost to true
						keystroke "t" using command down
					end tell
				end tell
				delay 0.1
				tell application "Terminal"
					if (count of tabs of targetWindow) > originalTabCount then
						do script cdCommand in selected tab of targetWindow
						return
					end if
				end tell
			end try

			my launchTerminalAppNewTerminal(targetPath)
		end if
	on error
		do shell script "open -a Terminal " & quoted form of targetPath
	end try
end launchTerminalAppNewTab
