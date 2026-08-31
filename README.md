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

Install that build at its stable location before adding it to Finder:

```bash
./install.sh
```

Installed app:
- `/Applications/iTermPortal.app`

Terminal selection:
1. Launch `/Applications/iTermPortal.app` once.
2. Click the new menu bar icon.
3. Pick your default terminal.
4. Next Finder toolbar clicks open in that terminal.

## Versioning

Uses [ssmver](https://github.com/hjoncour/ssmver)

## CI/CD

Workflows:
- `build.yaml`: PR build validation
- `app-store-release-test.yaml`: Mac App Store package pipeline (`[release]` trigger, optional manual upload). **Note: App Store distribution is not currently a working end-user path — installed copies fail at runtime due to sandbox-specific issues that don't manifest in the locally-built Developer ID build. Use the Homebrew cask or the direct download instead. See `.docs/features/15_app_store_pipeline.md` §15.**
- `release.yaml`: pushes to `master` derive `vX.Y.Z` from `ssmver.toml`, update that GitHub Release, and update the Homebrew tap cask (`iTermPortal-macos.zip` + optional signed `iTermPortal-direct-install.pkg`)
- `certificate.yaml`: macOS certificate/notarization preflight

Setup guide (all variables + macOS cert instructions):
- `docs/homebrew-release.md`

## Add to Finder Toolbar

1. Build and install the app with `./scripts/build_applescript_app.sh && ./install.sh`.
2. Open `/Applications` in Finder.
3. Hold `Command` and drag `/Applications/iTermPortal.app` into Finder's toolbar.
4. Click the new toolbar icon to run it.
5. If Finder shows a question mark, hold `Command` and drag that broken item out of the toolbar, then add `/Applications/iTermPortal.app` again.

Do not add `dist/iTermPortal.app` to Finder's toolbar. `dist/` is a disposable build directory, and rebuilding it replaces the app object that Finder bookmarked. The `/Applications` path is the stable toolbar target.

## First-Run Permissions

On first use, macOS may prompt for Automation permissions so the app can read Finder context.
Grant once; repeated clicks should run without prompts.
