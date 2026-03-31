# iTermPortal

iTermPortal is now a native macOS menu bar app with an embedded Finder Sync extension.

What it does:
- Runs as a Dockless menu bar app (`LSUIElement=true`)
- Stores terminal preferences in an App Group shared by the app and extension
- Adds a Finder toolbar item that opens the current Finder folder in `Terminal`, `iTerm2`, `Ghostty`, or `Warp`
- Supports `New Terminal`, `New Window`, and `New Tab` launch modes

## Build

Fast local build script:

```bash
./scripts/build_app.sh
```

That produces:
- `dist/iTermPortal.app`
- `dist/iTermPortal.app/Contents/MacOS/iTermPortal`

Unsigned local build:

```bash
xcodebuild \
  -project iTermPortal.xcodeproj \
  -scheme iTermPortal \
  -configuration Debug \
  -derivedDataPath build/DerivedData \
  build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

App bundle output:
- `build/DerivedData/Build/Products/Debug/iTermPortal.app`

Install to `/Applications` with a single command:

```bash
./install.sh
```

Use `./install.sh --dest /some/other/folder` to install somewhere else without touching `/Applications`.

Unit tests:

```bash
xcodebuild \
  -project iTermPortal.xcodeproj \
  -scheme iTermPortalTests \
  -configuration Debug \
  -derivedDataPath build/DerivedData \
  test \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

## First Run

1. Launch `iTermPortal.app`.
2. Use the menu bar icon to choose your terminal and open mode.
3. Open `Manage Extension…` if Finder has not enabled the bundled Finder extension yet.
4. In Finder, click the iTermPortal toolbar item and choose `Open in …`.

If you choose `New Tab` for Terminal.app or iTerm2, macOS may prompt once for Apple Events access to that terminal app.

## Icons

The app icon source files live in `assets/icons/`.

- `assets/icons/negative.png` is used for the installed app icon sizes
- `assets/icons/input.png` is used for the 1024px App Store slot

Regenerate the committed asset catalog PNGs with:

```bash
./scripts/generate_icons.sh
```

## Project Layout

- `Sources/iTermPortal/` contains the menu bar app
- `Sources/iTermPortalSync/` contains the Finder Sync extension
- `Sources/Shared/` contains shared preferences and terminal launch logic
- `Resources/` contains the app and extension plists plus the asset catalog
- `Entitlements/` contains App Store and direct-install entitlement files

## CI/CD

Workflows:
- `build.yaml` builds an unsigned Debug app for pull requests
- `app-store-release-test.yaml` archives and exports the App Store build
- `release.yaml` archives, exports, notarizes, and publishes the direct-install zip when signing secrets are configured

Versioning uses [ssmver](https://github.com/hjoncour/ssmver).

`scripts/build_applescript_app.sh` is kept only for the legacy AppleScript implementation and is not used by the native app build.
