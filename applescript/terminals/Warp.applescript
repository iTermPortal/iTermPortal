on launchWarp(targetPath, openMode)
	if openMode is "new_tab" then
		my launchWarpNewTab(targetPath)
	else if openMode is "new_window" then
		my launchWarpNewWindow(targetPath)
	else
		my launchWarpNewTerminal(targetPath)
	end if
end launchWarp

on launchWarpNewTerminal(targetPath)
	try
		do shell script "open -na Warp " & quoted form of targetPath
	on error
		my launchWarpNewWindow(targetPath)
	end try
end launchWarpNewTerminal

on launchWarpNewWindow(targetPath)
	try
		set encodedPath to my urlEncodePath(targetPath)
		do shell script "open 'warp://action/new_window?path=" & encodedPath & "'"
	on error
		my launchFallbackTerminal("Warp", targetPath, "new_window")
	end try
end launchWarpNewWindow

on launchWarpNewTab(targetPath)
	try
		set encodedPath to my urlEncodePath(targetPath)
		do shell script "open 'warp://action/new_tab?path=" & encodedPath & "'"
	on error
		my launchWarpNewWindow(targetPath)
	end try
end launchWarpNewTab

on urlEncodePath(targetPath)
	return do shell script "python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' " & quoted form of targetPath
end urlEncodePath
