on launchWarp(targetPath, openMode)
	if openMode is "new_tab" then
		my launchWarpNewTab(targetPath)
	else
		my launchWarpNewTerminal(targetPath)
	end if
end launchWarp

on launchWarpNewTerminal(targetPath)
	try
		do shell script "open -na Warp " & quoted form of targetPath
	on error
		my launchFallbackTerminal("Warp", targetPath, "new_terminal")
	end try
end launchWarpNewTerminal

on launchWarpNewTab(targetPath)
	try
		do shell script "open -a Warp " & quoted form of targetPath
	on error
		my launchWarpNewTerminal(targetPath)
	end try
end launchWarpNewTab
