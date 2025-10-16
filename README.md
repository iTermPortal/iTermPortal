# fPortal

A minimal macOS host app + Finder Sync extension that adds a **“Code”** toolbar button in Finder.  
Clicking **Code** opens the **current Finder folder** (or the current selection) in your preferred app  
(default: **Visual Studio Code**, bundle id `com.microsoft.VSCode`). The preferred app can be changed in the host app’s **Settings**.

---

## Requirements

- macOS 13+ (Ventura) or later
- Xcode 15 or 16
- A valid Apple Developer Team set in the project’s Signing settings
- Visual Studio Code (or any target app you prefer)

---

## Repository layout
.
├─ Info.plist                          # Host app plist
├─ fPortal/
│  ├─ OpenInAppApp.swift               # Host app @main
│  ├─ SettingsView.swift               # Preferred bundle id editor (App Group)
│  └─ fPortal.entitlements             # Host entitlements
├─ fPortalFinderExtension/
│  ├─ FinderSync.swift                 # Finder Sync implementation
│  ├─ Info.plist                       # Extension plist (NSExtension)
│  └─ fPortalFinderExtension.entitlements
└─ fPortal.xcodeproj/…

App Group used in code (can be changed):  
`group.com.hjoncour.fPortal`

---

## First-time setup (Xcode)

> Do these once to wire targets, entitlements, and embedding.

### 1) Configure Signing

- In Xcode, open **fPortal.xcodeproj**.
- Select **fPortal** (host app) target → **Signing & Capabilities**:
  - **Team:** choose your team.
  - Ensure a unique **Bundle Identifier** (e.g., `com.hjoncour.fPortal`).
- Select **fPortalFinderExtension** target → **Signing & Capabilities**:
  - **Team:** choose the same team.
  - Unique **Bundle Identifier** (e.g., `com.hjoncour.fPortal.FinderExtension`).

### 2) App Sandbox & App Group entitlements

- **Host app** target → **Signing & Capabilities**:
  - Add **App Sandbox** (default enabled).
  - Add **App Groups** → plus (+) → **group.com.hjoncour.fPortal**.
    - This must match the constant in `SettingsView.swift`.
- **Extension** target → **Signing & Capabilities**:
  - Add **App Sandbox**.
  - Add **App Groups** → **group.com.hjoncour.fPortal**.
    - This must match the constant in `FinderSync.swift`.

If you prefer **not** to use App Groups yet, remove the App Group capability from both targets and:
- In `SettingsView.swift`, use plain `@AppStorage("preferredBundleID")` (no suiteName).
- In `FinderSync.swift`, hardcode `"com.microsoft.VSCode"` in `preferredBundleID()`.

### 3) Target membership sanity check

- `FinderSync.swift` (in **fPortalFinderExtension/**) should be **only** in the **fPortalFinderExtension** target.
- `OpenInAppApp.swift` and `SettingsView.swift` should be **only** in the **fPortal** (host) target.
- There should be **one** `@main` (in `OpenInAppApp.swift`).

### 4) Extension Info.plist (already present)

Confirm `fPortalFinderExtension/Info.plist` contains:

```xml
<NSExtension>
  <key>NSExtensionPointIdentifier</key>
  <string>com.apple.finder.sync-service</string>
  <key>NSExtensionPrincipalClass</key>
  <string>$(PRODUCT_MODULE_NAME).FinderSync</string>
</NSExtension>

