# iTermPortal: Finder "Open Terminal Here" (AppleScript)

This repository builds a tiny AppleScript app for Finder's toolbar.

Behavior:
- Click the toolbar icon in Finder.
- Terminal opens in that Finder window's current folder.
- If a file is selected, Terminal opens in that file's parent folder.
- The app runs without a Dock icon (`LSUIElement=true`).
- A menu bar icon lets you choose the terminal app (`Terminal`, `iTerm2`, `Ghostty`, `Warp`).

Icon source:
- `assets/icons/negative.png` (converted to app icon during build)

## Build

```bash
./scripts/build_applescript_app.sh
```

Output app:
- `dist/iTermPortal.app`

Terminal selection:
1. Launch `dist/iTermPortal.app` once.
2. Click the new menu bar icon.
3. Pick your default terminal.
4. Next Finder toolbar clicks open in that terminal.

## Versioning

Version format:
- `major.feature.fix` (stored in `VERSION`)

Auto-bump rules:
- `release(scope): ...` or `major(scope): ...` -> bump `major`
- `feature(scope): ...` -> bump `feature`
- `fix(scope): ...` -> bump `fix`

PR guardrail:
- Exactly one bump per PR branch.
- If `VERSION` is already bumped on that branch, additional commits do nothing.
- Hook intentionally skips direct commits on `main`/`master`.

Hook install (run once per clone):

```bash
./scripts/install_git_hooks.sh
```

## CI/CD

Workflows:
- `build.yaml`: PR build validation
- `app-store-release-test.yaml`: Mac App Store package pipeline (`[release]` trigger, optional manual upload)
- `release.yaml`: push to `main`/`master` builds and publishes GitHub Release assets (`iTermPortal-macos.zip` + optional signed `iTermPortal-direct-install.pkg`)
- `certificate.yaml`: macOS certificate/notarization preflight

Setup guide (all variables + macOS cert instructions):
- `docs/github-actions.md`
- `docs/app-store-release.md`

## Add to Finder Toolbar

1. Open a Finder window.
2. Hold `Command` and drag `dist/iTermPortal.app` into Finder's toolbar.
3. Click the new toolbar icon to run it.
4. If Finder still shows an old icon, remove the toolbar item, relaunch Finder, and drag `dist/iTermPortal.app` back in.

## First-Run Permissions

On first use, macOS may prompt for Automation permissions so the app can read Finder context.
Grant once; repeated clicks should run without prompts.

## Acceptance Checks

1. Open Finder at `/Users/hjoncour/Projects`, click icon, run `pwd` in Terminal.
2. Open Finder at `/Users/hjoncour/Downloads/studio/test_linkedin_9f7a1e80/frames`, click icon, run `pwd`.
3. Select a file in Finder, click icon, verify Terminal opens in the containing folder.
4. Restart Finder (`Option` + right-click Finder in Dock -> `Relaunch`), confirm toolbar icon remains and still works.
5. Click repeatedly while changing folders; each click should open in the folder visible at click time.
