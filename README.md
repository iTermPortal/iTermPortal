# fPortal: Finder "Open Terminal Here" (AppleScript)

This repository builds a tiny AppleScript app for Finder's toolbar.

Behavior:
- Click the toolbar icon in Finder.
- Terminal opens in that Finder window's current folder.
- If a file is selected, Terminal opens in that file's parent folder.
- The app runs without a Dock icon (`LSUIElement=true`).

## Build

```bash
./scripts/build_applescript_app.sh
```

Output app:
- `dist/fPortal.app`

## Add to Finder Toolbar

1. Open a Finder window.
2. Hold `Command` and drag `dist/fPortal.app` into Finder's toolbar.
3. Click the new toolbar icon to run it.

## First-Run Permissions

On first use, macOS may prompt for Automation permissions so the app can read Finder context.
Grant once; repeated clicks should run without prompts.

## Acceptance Checks

1. Open Finder at `/Users/hjoncour/Projects`, click icon, run `pwd` in Terminal.
2. Open Finder at `/Users/hjoncour/Downloads/studio/test_linkedin_9f7a1e80/frames`, click icon, run `pwd`.
3. Select a file in Finder, click icon, verify Terminal opens in the containing folder.
4. Restart Finder (`Option` + right-click Finder in Dock -> `Relaunch`), confirm toolbar icon remains and still works.
5. Click repeatedly while changing folders; each click should open in the folder visible at click time.
