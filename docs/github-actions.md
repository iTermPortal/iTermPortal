# GitHub Actions: Build, Release, Certs

## Workflows

- `build.yaml`
  - Purpose: PR build validation for `fPortal.app`.
  - Trigger: pull requests (`opened`, `synchronize`, `reopened`, `ready_for_review`).
- `release.yaml`
  - Purpose: signed macOS build + optional notarization + GitHub Release.
  - Trigger: `workflow_dispatch`, or push to `main`/`master` when commit message contains `[release]`.
- `certificate.yaml`
  - Purpose: Apple cert/notarization preflight without publishing.
  - Trigger: `workflow_dispatch`, or non-`main`/`master` pushes with commit message containing `[apple-cert-check]`.

## Variables and Secrets

### GitHub-provided token

- `GITHUB_TOKEN`
  - Used by: `release.yaml`
  - Source: automatically provided by GitHub Actions

### Repository secrets (Settings -> Secrets and variables -> Actions)

| Name | Used by | Required | Description |
| --- | --- | --- | --- |
| `APPLE_CERTIFICATE` | `release.yaml`, `certificate.yaml` | Yes (for signing) | Base64-encoded `.p12` that includes **Developer ID Application** cert + private key |
| `APPLE_CERTIFICATE_PASSWORD` | `release.yaml`, `certificate.yaml` | Yes (for signing) | Password used when exporting the `.p12` |
| `KEYCHAIN_PASSWORD` | `release.yaml`, `certificate.yaml` | Yes (for signing) | Password for temporary CI keychain |
| `APPLE_API_KEY_P8` | `release.yaml`, `certificate.yaml` | Optional (recommended) | Full content of App Store Connect API `.p8` file |
| `APPLE_API_KEY` | `release.yaml`, `certificate.yaml` | Optional (with `APPLE_API_KEY_P8`) | App Store Connect API key ID |
| `APPLE_API_ISSUER` | `release.yaml`, `certificate.yaml` | Optional (with `APPLE_API_KEY_P8`) | App Store Connect issuer ID (UUID) |
| `APPLE_ID` | `release.yaml`, `certificate.yaml` | Optional fallback | Apple ID email for notarization fallback |
| `APPLE_PASSWORD` | `release.yaml`, `certificate.yaml` | Optional fallback | App-specific password for Apple ID |
| `APPLE_TEAM_ID` | `release.yaml`, `certificate.yaml` | Optional fallback | Apple Developer Team ID |

### Runtime environment variables set in workflows

| Name | Set by | Purpose |
| --- | --- | --- |
| `KEYCHAIN_PATH` | `release.yaml`, `certificate.yaml` | Temporary keychain path on macOS runner |
| `APPLE_SIGNING_IDENTITY` | `release.yaml`, `certificate.yaml` | Developer ID identity discovered after import |
| `CODESIGN_ALLOCATE` | `release.yaml`, `certificate.yaml` | `codesign_allocate` path |
| `HAS_P8` | `release.yaml`, `certificate.yaml` | Flag that `.p8` credential exists |
| `HAS_NOTARY_CREDS` | `release.yaml`, `certificate.yaml` | Flag that notarization credentials are available |

## How To Get macOS Certificates

### 1) Create Developer ID Application certificate

1. Make sure Apple Developer Program membership is active.
2. Open `Keychain Access` -> `Certificate Assistant` -> `Request a Certificate From a Certificate Authority...`.
3. Save the CSR locally.
4. In Apple Developer portal (`Certificates, IDs & Profiles`) create a new certificate:
   - Type: **Developer ID Application** (not Developer ID Installer).
5. Upload CSR and download the generated `.cer`.
6. Open the `.cer` to import it into Keychain.

### 2) Export `.p12` with private key

1. In `Keychain Access`, find `Developer ID Application: <Name> (<TEAMID>)`.
2. Ensure the private key is present under the certificate.
3. Right-click certificate -> `Export`.
4. Export as `.p12` and set a password.
5. That password is your `APPLE_CERTIFICATE_PASSWORD`.

### 3) Convert `.p12` to base64 for `APPLE_CERTIFICATE`

macOS:

```bash
base64 -i developer_id_application.p12 | pbcopy
```

Linux:

```bash
base64 -w 0 developer_id_application.p12
```

PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("developer_id_application.p12"))
```

Paste the output into the `APPLE_CERTIFICATE` GitHub secret.

## How To Get Notarization Credentials

Preferred path: App Store Connect API key

1. Go to App Store Connect -> Users and Access -> Integrations -> App Store Connect API.
2. Create a key and download the `.p8` file (download is one-time).
3. Set secrets:
   - `APPLE_API_KEY` (Key ID)
   - `APPLE_API_ISSUER` (Issuer ID)
   - `APPLE_API_KEY_P8` (full `.p8` file content)

Fallback path: Apple ID

1. Set `APPLE_ID` (email).
2. Create app-specific password on appleid.apple.com and set `APPLE_PASSWORD`.
3. Set `APPLE_TEAM_ID`.

## Recommended Rollout

1. Add required secrets (`APPLE_CERTIFICATE`, `APPLE_CERTIFICATE_PASSWORD`, `KEYCHAIN_PASSWORD`).
2. Add notarization secrets (API key path preferred).
3. Run `certificate.yaml` first to verify signing/notarization.
4. Run `release.yaml` via `workflow_dispatch` (or push with `[release]` in commit message).
