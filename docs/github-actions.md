# GitHub Actions: Build, Release, Certs

## Workflows

- `build.yaml`
  - Purpose: PR build validation for `iTermPortal.app`.
  - Trigger: pull requests (`opened`, `synchronize`, `reopened`, `ready_for_review`).
- `release.yaml`
  - Purpose: build/package app and create a GitHub Release (`.zip` + optional signed direct-install `.pkg`).
  - Trigger: every push to `main` or `master`, plus `workflow_dispatch`.
  - Note: no `[release]` keyword is required for this workflow.
- `app-store-release-test.yaml`
  - Purpose: Mac App Store packaging/signing with optional upload on manual runs.
  - Trigger: `workflow_dispatch`, or push when commit message contains `[release]`.
- `certificate.yaml`
  - Purpose: Apple cert/notarization preflight without publishing.
  - Trigger: `workflow_dispatch`, or non-`main`/`master` pushes with commit message containing `[apple-cert-check]`.

## Secret Mapping

### For `release.yaml`

Required for signed release:
- `KEYCHAIN_PASSWORD`
- One certificate/password pair:
  - Preferred: `APPLE_CERTIFICATE` + `APPLE_CERTIFICATE_PASSWORD`
  - Fallback: `APPLE_APP_DIST_CERTIFICATE` + `APPLE_APP_DIST_CERTIFICATE_PASSWORD`

Optional for signed direct-install `.pkg` in Release assets:
- One installer certificate/password pair:
  - Preferred: `APPLE_INSTALLER_CERTIFICATE` + `APPLE_INSTALLER_CERTIFICATE_PASSWORD`
  - Fallback: `APPLE_INSTALLER_DIST_CERTIFICATE` + `APPLE_INSTALLER_DIST_CERTIFICATE_PASSWORD`

Optional for notarization:
- API key path:
  - `APPLE_API_KEY` or `APPLE_API_KEY_ID_FPORTAL` or `APPLE_API_KEY_FPORTAL`
  - `APPLE_API_ISSUER`
  - `APPLE_API_KEY_P8`
- Apple ID fallback path:
  - `APPLE_ID`
  - `APPLE_PASSWORD`
  - `APPLE_TEAM_ID`

Notes:
- If signing secrets are missing, release still runs and publishes an unsigned artifact.
- If installer cert secrets are set, release also publishes `iTermPortal-direct-install.pkg` (install without unzipping).
- If notarization is configured and fails, the run warns and continues to release creation.

### For `app-store-release-test.yaml`

Required:
- `APPLE_TEAM_ID`
- `APPLE_APP_DIST_CERTIFICATE`
- `APPLE_APP_DIST_CERTIFICATE_PASSWORD`
- `APPLE_INSTALLER_DIST_CERTIFICATE`
- `APPLE_INSTALLER_DIST_CERTIFICATE_PASSWORD`
- `APPLE_PROVISIONING_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`
- Bundle ID via either:
  - repo variable `APPLE_APP_BUNDLE_ID`, or
  - repo secret `APPLE_APP_BUNDLE_ID`

Optional App Store Connect validation:
- `APPLE_API_KEY` or `APPLE_API_KEY_ID_FPORTAL` or `APPLE_API_KEY_FPORTAL`
- `APPLE_API_ISSUER`
- `APPLE_API_KEY_P8`

Manual upload mode:
- Run workflow with `upload_to_app_store=true` to call `altool --upload-app`.

## Quick Troubleshooting

1. If no workflow ran after merge:
   - verify the workflow file exists on default branch under `.github/workflows/`.
   - verify repo Actions are enabled in GitHub settings.
   - verify push landed on `main` or `master` for `release.yaml`.
2. In `release.yaml` logs, check `Resolve release config and diagnostics`.
   - this prints which secret alias was detected and whether signing/notarization are enabled.
3. If release creation fails:
   - ensure `permissions: contents: write` remains in `release.yaml`.
   - ensure repository-level workflow permissions allow write for `GITHUB_TOKEN`.
