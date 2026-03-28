# App Store Release Test (iTermPortal)

This repo contains `app-store-release-test.yaml` to validate Mac App Store signing/package flow and optionally upload to App Store Connect.

Important:
- The current app resolves Finder context by scripting Finder directly from AppleScript.
- That works in the direct-install build because it is unsandboxed.
- The Mac App Store build is sandboxed, so signing/package success does not mean the runtime behavior matches the GitHub release.
- The workflow now fails fast before packaging while this limitation exists, so broken App Store runtime builds are easier to catch in CI.

## Trigger

- Manual: GitHub -> Actions -> `App Store Release Pipeline Test (iTermPortal)` -> `Run workflow`
  - Set `upload_to_app_store=true` to upload the built package to App Store Connect.
- Commit trigger: include `[release]` in commit message

Examples:
- `fix(ci): adjust app-store test [release]`
- `feature(build): app store pipeline check [release]`

## Required Secrets/Variables

Required secrets:
- `APPLE_TEAM_ID`
- `APPLE_APP_DIST_CERTIFICATE`
- `APPLE_APP_DIST_CERTIFICATE_PASSWORD`
- `APPLE_INSTALLER_DIST_CERTIFICATE`
- `APPLE_INSTALLER_DIST_CERTIFICATE_PASSWORD`
- `APPLE_PROVISIONING_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`

Bundle ID:
- preferred: repo variable `APPLE_APP_BUNDLE_ID`
- fallback: repo secret `APPLE_APP_BUNDLE_ID`

Optional App Store Connect validation:
- `APPLE_API_KEY` or `APPLE_API_KEY_ID_FPORTAL` or `APPLE_API_KEY_FPORTAL`
- `APPLE_API_ISSUER`
- `APPLE_API_KEY_P8`

Upload prerequisites:
- App Store Connect must already contain an app record for the exact bundle ID in `APPLE_APP_BUNDLE_ID`.
- The API key must have access to that app (Admin or App Manager role, with app access not restricted away from this app).

## What the Workflow Verifies

When the fail-fast guard does not trigger, the workflow verifies:

1. Secrets and bundle-id presence.
2. Provisioning profile parsing.
3. Bundle ID and Team ID match profile entitlements.
4. App signing identity import.
5. Installer signing identity import.
6. Build/sign of `dist/iTermPortal.app`.
7. Build/sign of `dist/iTermPortal-app-store.pkg`.
8. Optional `altool --validate-app`.
9. For manual upload mode, CI verifies your API key can see the exact bundle ID in App Store Connect.
10. Optional `altool --upload-app` (manual runs only, when `upload_to_app_store=true`).

## Runtime Parity

- `release.yaml` and `app-store-release-test.yaml` do not currently produce runtime-equivalent builds.
- For reliable App Store testing, install and test `dist/iTermPortal-app-store.pkg` itself or use TestFlight/App Store Connect distribution.
- If the goal is one code path that behaves the same on GitHub and in the Mac App Store, the Finder toolbar integration needs to move away from direct Finder Apple events and onto a sandbox-compatible mechanism.

## Artifacts

On success, the workflow uploads:
- `dist/iTermPortal.app`
- `dist/iTermPortal-app-store.pkg`
- `appstore-apps.json` (when API app list check runs)
- `profile.plist`

Important:
- `dist/iTermPortal-app-store.pkg` is the package for App Store Connect upload.
- `iTermPortal-direct-install.pkg` from `release.yaml` is for direct installation and is not the App Store submission package.
