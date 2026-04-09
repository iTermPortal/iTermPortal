# Homebrew Tap Release Automation

This repository should publish to Homebrew as a cask, not a formula.

Why:
- `iTermPortal` is a macOS GUI app bundle (`dist/iTermPortal.app`), not a CLI binary.
- The signed release artifact is a zipped `.app` (`iTermPortal-macos.zip`), which maps directly to a Homebrew cask.

## Release Flow

1. Update `ssmver.toml` to the version you want to release.
2. Create and push a matching tag: `vX.Y.Z`.
3. `.github/workflows/release.yaml` runs on that tag.
4. The workflow:
   - validates the tag matches `ssmver.toml`
   - builds `dist/iTermPortal.app`
   - re-signs and notarizes it when Apple secrets are configured
   - packages `dist/iTermPortal-macos.zip`
   - computes the asset SHA256
   - creates or updates the GitHub Release for that tag
   - checks out your separate tap repo
   - writes `Casks/itermportal.rb`
   - commits and pushes the cask update to the tap repo

The cask always points at:

```text
https://github.com/<owner>/<repo>/releases/download/v<version>/iTermPortal-macos.zip
```

That means the release asset name must stay `iTermPortal-macos.zip`.

## Required Repository Configuration

Existing release signing/notarization secrets are still used by `release.yaml`:
- `KEYCHAIN_PASSWORD`
- `APPLE_CERTIFICATE` and `APPLE_CERTIFICATE_PASSWORD`
- optional notarization secrets:
  - `APPLE_API_KEY` or `APPLE_API_KEY_ID_FPORTAL` or `APPLE_API_KEY_FPORTAL`
  - `APPLE_API_ISSUER`
  - `APPLE_API_KEY_P8`
- optional Apple ID fallback:
  - `APPLE_ID`
  - `APPLE_PASSWORD`
  - `APPLE_TEAM_ID`

New Homebrew-specific configuration:
- Repository variable: `HOMEBREW_TAP_REPOSITORY`
  - Example: `iTermPortal/homebrew-tap`
- Repository secret: `HOMEBREW_TAP_GITHUB_TOKEN`
  - Use a fine-grained PAT or GitHub App token with `Contents: Read and write` access to the tap repo.

If the tap variable or token is missing, the release workflow fails before publishing.

## Tap Repository Layout

The separate tap repo must already exist and should contain at least:

```text
homebrew-tap/
  Casks/
    itermportal.rb
```

Recommended repo name:
- `<owner>/homebrew-tap`

Install command for users:

```bash
brew tap <owner>/tap
brew install --cask <owner>/tap/itermportal
```

If your repo is named `homebrew-tap`, the tap shorthand is `<owner>/tap`.

## Local Testing

Build the app:

```bash
./scripts/build_applescript_app.sh
```

Package the release zip:

```bash
./scripts/package_release_zip.sh dist/iTermPortal.app dist/iTermPortal-macos.zip
```

Render the cask locally:

```bash
python3 scripts/render_homebrew_cask.py \
  --template packaging/homebrew/Casks/itermportal.rb.template \
  --output /tmp/itermportal.rb \
  --version "$(python3 scripts/get_version.py)" \
  --sha256 "$(shasum -a 256 dist/iTermPortal-macos.zip | awk '{print $1}')" \
  --repository "iTermPortal/iTermPortal" \
  --asset-name "iTermPortal-macos.zip"
ruby -c /tmp/itermportal.rb
```

Simulate the tap update against a local git repo:

```bash
TMP_TAP="$(mktemp -d)"
git init --initial-branch=main "$TMP_TAP"
TAP_PATH="$TMP_TAP" \
RELEASE_VERSION="$(python3 scripts/get_version.py)" \
RELEASE_SHA256="$(shasum -a 256 dist/iTermPortal-macos.zip | awk '{print $1}')" \
RELEASE_ASSET_NAME="iTermPortal-macos.zip" \
SOURCE_REPOSITORY="iTermPortal/iTermPortal" \
./scripts/update_homebrew_tap.sh
```

## Manual Setup Still Required

You still need to do these steps outside this repo:

1. Create the tap repository.
2. Add `HOMEBREW_TAP_REPOSITORY` as a repository variable in this repo.
3. Add `HOMEBREW_TAP_GITHUB_TOKEN` as a repository secret in this repo.
4. Ensure your release tags use `vX.Y.Z` and match `ssmver.toml`.
5. Keep publishing the signed app zip as `iTermPortal-macos.zip`.
