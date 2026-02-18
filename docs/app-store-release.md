# App Store Release Test (fPortal)

This repo contains `app-store-release-test.yaml` to validate Mac App Store signing/package flow without uploading.

## Trigger

- Manual: GitHub -> Actions -> `App Store Release Pipeline Test (fPortal)` -> `Run workflow`
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

## What the Workflow Verifies

1. Secrets and bundle-id presence.
2. Provisioning profile parsing.
3. Bundle ID and Team ID match profile entitlements.
4. App signing identity import.
5. Installer signing identity import.
6. Build/sign of `dist/fPortal.app`.
7. Build/sign of `dist/fPortal-app-store.pkg`.
8. Optional `altool --validate-app`.

## Artifacts

On success, the workflow uploads:
- `dist/fPortal.app`
- `dist/fPortal-app-store.pkg`
- `profile.plist`
