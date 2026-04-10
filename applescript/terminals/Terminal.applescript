on launchTerminalApp(targetPath, openMode)
	if openMode is "new_tab" then
		my launchTerminalAppNewTab(targetPath)
	else if openMode is "new_window" then
		my launchTerminalAppNewWindow(targetPath)
	else
		my launchTerminalAppNewTerminal(targetPath)
	end if
end launchTerminalApp

on launchTerminalAppNewWindow(targetPath)
	set cdCommand to "cd " & quoted form of targetPath
	try
		tell application "Terminal"
			activate
			do script cdCommand
		end tell
	on error
		do shell script "open -a Terminal " & quoted form of targetPath
	end try
end launchTerminalAppNewWindow

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
		tell application "Terminal" to activate

		if (my countTerminalWindows()) is 0 then
			tell application "Terminal" to do script cdCommand
			return
		end if

		if not my hasAccessibilityPermission() then
			my promptForAccessibilityPermission()
			do shell script "open -a Terminal " & quoted form of targetPath
			return
		end if

		tell application "System Events"
			tell process "Terminal" to set frontmost to true
		end tell
		delay 0.12
		tell application "System Events"
			tell process "Terminal" to keystroke "t" using command down
		end tell
		delay 0.35
		tell application "Terminal"
			do script cdCommand in front window
		end tell
	on error
		do shell script "open -a Terminal " & quoted form of targetPath
	end try
end launchTerminalAppNewTab

on countTerminalWindows()
	try
		tell application "Terminal"
			return count of windows
		end tell
	on error
		return 0
	end try
end countTerminalWindows

on hasAccessibilityPermission()
	try
		tell application "System Events"
			return UI elements enabled
		end tell
	on error
		return false
	end try
end hasAccessibilityPermission

on promptForAccessibilityPermission()
	try
		display dialog ¬
			"To open Terminal in a new tab, iTermPortal needs Accessibility permission." & return & return & ¬
			"Add iTermPortal in System Settings → Privacy & Security → Accessibility, then try again. Until then, Terminal will open in a new window." ¬
			buttons {"Not now", "Open Settings"} default button "Open Settings" with title "iTermPortal"
		if button returned of result is "Open Settings" then
			do shell script "open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility'"
		end if
	end try
end promptForAccessibilityPermission
