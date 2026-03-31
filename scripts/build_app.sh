#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/iTermPortal.xcodeproj"
SCHEME="iTermPortal"
CONFIGURATION="${FPORTAL_CONFIGURATION:-Debug}"
DERIVED_DATA_PATH="${FPORTAL_DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedData}"
DIST_DIR="$ROOT_DIR/dist"
DIST_APP_PATH="$DIST_DIR/iTermPortal.app"
APP_ENTITLEMENTS="$ROOT_DIR/Entitlements/iTermPortal-DirectInstall.entitlements"
EXTENSION_ENTITLEMENTS="$ROOT_DIR/Entitlements/iTermPortalSync-DirectInstall.entitlements"
APP_BUNDLE_ID="com.hjoncour.fPortal"
SYNC_BUNDLE_ID="com.hjoncour.fPortal.FinderExtension"
APP_GROUP_ID="group.com.hjoncour.fPortal"
COPY_TO_DIST=1
DEVELOPMENT_TEAM="${FPORTAL_DEVELOPMENT_TEAM:-}"
ALLOW_PROVISIONING_UPDATES=0
SIGNING_IDENTITY="${FPORTAL_SIGNING_IDENTITY:-}"
MAIN_PROVISIONING_PROFILE="${FPORTAL_MAIN_PROVISIONING_PROFILE:-}"
SYNC_PROVISIONING_PROFILE="${FPORTAL_SYNC_PROVISIONING_PROFILE:-}"

usage() {
  cat <<'EOF'
Usage: ./scripts/build_app.sh [options]

Build the native iTermPortal macOS app from the Xcode project.

Options:
  --configuration <name>  Xcode build configuration (default: Debug)
  --development-team <id> Use Apple Development signing for Finder Sync
  --derived-data <path>   DerivedData output path (default: build/DerivedData)
  --allow-provisioning-updates
                          Let xcodebuild create/download development profiles
  --signing-identity <id> Manually sign the built app with this certificate
  --main-profile <path>   Provisioning profile for com.hjoncour.fPortal
  --sync-profile <path>   Provisioning profile for com.hjoncour.fPortal.FinderExtension
  --no-copy-to-dist       Leave the built app inside DerivedData only
  -h, --help              Show this help
EOF
}

cleanup_temp_files() {
  if [[ $# -gt 0 ]]; then
    rm -f "$@"
  fi
}

required_signing_assets_message() {
  cat <<EOF
Required signing assets for a working Finder Sync build:
  App bundle id: $APP_BUNDLE_ID
  Extension bundle id: $SYNC_BUNDLE_ID
  Shared App Group: $APP_GROUP_ID
EOF
}

profile_value() {
  local profile_path="$1"
  local plist_key="$2"
  local decoded_plist

  decoded_plist="$(mktemp)"
  if ! security cms -D -i "$profile_path" >"$decoded_plist" 2>/dev/null; then
    cleanup_temp_files "$decoded_plist"
    return 1
  fi

  /usr/libexec/PlistBuddy -c "Print :$plist_key" "$decoded_plist" 2>/dev/null || true
  cleanup_temp_files "$decoded_plist"
}

validate_manual_signing_assets() {
  local signing_team
  local expected_main_app_id
  local expected_sync_app_id
  local main_app_id
  local sync_app_id

  if ! security find-identity -v -p codesigning 2>/dev/null | grep -Fq "\"$SIGNING_IDENTITY\""; then
    echo "Signing identity not found in the current keychains:" >&2
    echo "  $SIGNING_IDENTITY" >&2
    exit 1
  fi

  signing_team="$(sed -nE 's/.*\(([A-Z0-9]+)\)$/\1/p' <<<"$SIGNING_IDENTITY")"
  if [[ -z "$signing_team" ]]; then
    echo "Could not infer the team ID from the signing identity:" >&2
    echo "  $SIGNING_IDENTITY" >&2
    exit 1
  fi

  expected_main_app_id="$signing_team.$APP_BUNDLE_ID"
  expected_sync_app_id="$signing_team.$SYNC_BUNDLE_ID"
  main_app_id="$(profile_value "$MAIN_PROVISIONING_PROFILE" "Entitlements:application-identifier")"
  sync_app_id="$(profile_value "$SYNC_PROVISIONING_PROFILE" "Entitlements:application-identifier")"

  if [[ "$main_app_id" != "$expected_main_app_id" ]]; then
    echo "Main provisioning profile does not match the app bundle identifier." >&2
    echo "Expected application-identifier: $expected_main_app_id" >&2
    echo "Actual application-identifier:   ${main_app_id:-<missing>}" >&2
    exit 1
  fi

  if [[ "$sync_app_id" != "$expected_sync_app_id" ]]; then
    echo "Sync provisioning profile does not match the Finder Sync bundle identifier." >&2
    echo "Expected application-identifier: $expected_sync_app_id" >&2
    echo "Actual application-identifier:   ${sync_app_id:-<missing>}" >&2
    exit 1
  fi

  if [[ "$(profile_value "$MAIN_PROVISIONING_PROFILE" "Entitlements:com.apple.security.application-groups:0")" != "$APP_GROUP_ID" ]]; then
    echo "Main provisioning profile is missing the shared App Group entitlement:" >&2
    echo "  $APP_GROUP_ID" >&2
    exit 1
  fi

  if [[ "$(profile_value "$SYNC_PROVISIONING_PROFILE" "Entitlements:com.apple.security.application-groups:0")" != "$APP_GROUP_ID" ]]; then
    echo "Sync provisioning profile is missing the shared App Group entitlement:" >&2
    echo "  $APP_GROUP_ID" >&2
    exit 1
  fi

}

explain_xcodebuild_failure() {
  local build_log="$1"
  if grep -Fq "No Account for Team" "$build_log"; then
    cat >&2 <<EOF

Signing diagnosis:
Xcode cannot access the requested Apple team from the command line on this Mac.

What to do:
  1. Open Xcode > Settings > Accounts and re-authenticate the Apple account for the target team.
  2. Download profiles from Xcode, or provide profiles manually with --main-profile and --sync-profile.
EOF
    return
  fi

  if grep -Fq "No profiles for '$APP_BUNDLE_ID'" "$build_log" || grep -Fq "No profiles for '$SYNC_BUNDLE_ID'" "$build_log"; then
    cat >&2 <<EOF

Signing diagnosis:
Xcode could not find explicit provisioning profiles for this app and extension.

EOF
    required_signing_assets_message >&2
    return
  fi

  if grep -Fq "No signing certificate \"Apple Development\" found" "$build_log"; then
    cat >&2 <<EOF

Signing diagnosis:
This Mac does not currently have an Apple Development certificate for the selected team.

What to do:
  1. In Xcode > Settings > Accounts > Manage Certificates, create or download an Apple Development certificate for the correct team.
  2. Retry this build after the certificate is visible in Keychain Access.
EOF
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --configuration)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      CONFIGURATION="$2"
      shift 2
      ;;
    --development-team)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      DEVELOPMENT_TEAM="$2"
      shift 2
      ;;
    --derived-data)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      DERIVED_DATA_PATH="$2"
      shift 2
      ;;
    --signing-identity)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      SIGNING_IDENTITY="$2"
      shift 2
      ;;
    --main-profile)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      MAIN_PROVISIONING_PROFILE="$2"
      shift 2
      ;;
    --sync-profile)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      SYNC_PROVISIONING_PROFILE="$2"
      shift 2
      ;;
    --allow-provisioning-updates)
      ALLOW_PROVISIONING_UPDATES=1
      shift
      ;;
    --no-copy-to-dist)
      COPY_TO_DIST=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Missing Xcode project: $PROJECT_PATH" >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is required and was not found." >&2
  exit 1
fi

if ! command -v codesign >/dev/null 2>&1; then
  echo "codesign is required and was not found." >&2
  exit 1
fi

if [[ -n "$DEVELOPMENT_TEAM" && -n "$SIGNING_IDENTITY" ]]; then
  echo "Choose either --development-team or --signing-identity, not both." >&2
  exit 1
fi

if [[ -n "$DEVELOPMENT_TEAM" && ( -n "$MAIN_PROVISIONING_PROFILE" || -n "$SYNC_PROVISIONING_PROFILE" ) ]]; then
  echo "Do not combine --development-team with manual profile options." >&2
  exit 1
fi

if [[ -n "$SIGNING_IDENTITY" || -n "$MAIN_PROVISIONING_PROFILE" || -n "$SYNC_PROVISIONING_PROFILE" ]]; then
  if [[ -z "$SIGNING_IDENTITY" || -z "$MAIN_PROVISIONING_PROFILE" || -z "$SYNC_PROVISIONING_PROFILE" ]]; then
    echo "Manual signing requires --signing-identity, --main-profile, and --sync-profile together." >&2
    exit 1
  fi

  validate_manual_signing_assets
fi

mkdir -p "$DIST_DIR"

echo "Building iTermPortal ($CONFIGURATION)..."

xcodebuild_args=(
  -project "$PROJECT_PATH"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -derivedDataPath "$DERIVED_DATA_PATH"
)

if [[ -n "$DEVELOPMENT_TEAM" ]]; then
  if [[ "$ALLOW_PROVISIONING_UPDATES" -eq 1 ]]; then
    xcodebuild_args+=(-allowProvisioningUpdates)
  fi

  xcodebuild_args+=(
    build
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"
    CODE_SIGN_STYLE=Automatic
    CODE_SIGN_IDENTITY="Apple Development"
  )
else
  xcodebuild_args+=(
    build
    CODE_SIGN_IDENTITY="-"
    CODE_SIGNING_REQUIRED=NO
    CODE_SIGNING_ALLOWED=NO
  )
fi

build_log="$(mktemp)"
set +e
xcodebuild "${xcodebuild_args[@]}" 2>&1 | tee "$build_log"
xcodebuild_status="${PIPESTATUS[0]}"
set -e

if [[ "$xcodebuild_status" -ne 0 ]]; then
  explain_xcodebuild_failure "$build_log"
  cleanup_temp_files "$build_log"
  exit "$xcodebuild_status"
fi

cleanup_temp_files "$build_log"

BUILT_APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/iTermPortal.app"
BUILT_EXTENSION_PATH="$BUILT_APP_PATH/Contents/PlugIns/iTermPortalSync.appex"

if [[ ! -d "$BUILT_APP_PATH" ]]; then
  echo "Build completed but app bundle was not found: $BUILT_APP_PATH" >&2
  exit 1
fi

if [[ ! -d "$BUILT_EXTENSION_PATH" ]]; then
  echo "Build completed but Finder Sync extension was not found: $BUILT_EXTENSION_PATH" >&2
  exit 1
fi

if [[ -n "$SIGNING_IDENTITY" ]]; then
  if [[ ! -f "$MAIN_PROVISIONING_PROFILE" ]]; then
    echo "Missing main provisioning profile: $MAIN_PROVISIONING_PROFILE" >&2
    exit 1
  fi

  if [[ ! -f "$SYNC_PROVISIONING_PROFILE" ]]; then
    echo "Missing sync provisioning profile: $SYNC_PROVISIONING_PROFILE" >&2
    exit 1
  fi

  cp "$MAIN_PROVISIONING_PROFILE" "$BUILT_APP_PATH/Contents/embedded.provisionprofile"
  cp "$SYNC_PROVISIONING_PROFILE" "$BUILT_EXTENSION_PATH/Contents/embedded.provisionprofile"

  codesign \
    --force \
    --sign "$SIGNING_IDENTITY" \
    --timestamp=none \
    --entitlements "$EXTENSION_ENTITLEMENTS" \
    "$BUILT_EXTENSION_PATH"

  codesign \
    --force \
    --sign "$SIGNING_IDENTITY" \
    --timestamp=none \
    --entitlements "$APP_ENTITLEMENTS" \
    --deep \
    "$BUILT_APP_PATH"
elif [[ -z "$DEVELOPMENT_TEAM" ]]; then
  codesign \
    --force \
    --sign - \
    --timestamp=none \
    --entitlements "$EXTENSION_ENTITLEMENTS" \
    "$BUILT_EXTENSION_PATH"

  codesign \
    --force \
    --sign - \
    --timestamp=none \
    --entitlements "$APP_ENTITLEMENTS" \
    --deep \
    "$BUILT_APP_PATH"
fi

if [[ "$COPY_TO_DIST" -eq 1 ]]; then
  rm -rf "$DIST_APP_PATH"
  ditto "$BUILT_APP_PATH" "$DIST_APP_PATH"
  APP_PATH="$DIST_APP_PATH"
else
  APP_PATH="$BUILT_APP_PATH"
fi

EXECUTABLE_PATH="$APP_PATH/Contents/MacOS/iTermPortal"

echo "App bundle: $APP_PATH"
echo "Executable: $EXECUTABLE_PATH"

if [[ -n "$SIGNING_IDENTITY" ]]; then
  echo "Signing: manual"
  echo "Identity: $SIGNING_IDENTITY"
  echo "Main profile: $MAIN_PROVISIONING_PROFILE"
  echo "Sync profile: $SYNC_PROVISIONING_PROFILE"
elif [[ -z "$DEVELOPMENT_TEAM" ]]; then
  detected_team="$(
    security find-identity -v -p codesigning 2>/dev/null |
      sed -nE 's/.*Apple Development:.*\(([A-Z0-9]+)\).*/\1/p' |
      sort -u |
      paste -sd ',' -
  )"

  echo "Note: this build is ad hoc signed. The app launches, but Finder Sync may still fail to load without a real development or distribution signature."
  if [[ -n "$detected_team" ]]; then
    echo "To build a fully working local Finder Sync bundle, rerun with: ./scripts/build_app.sh --development-team ${detected_team%%,*} --allow-provisioning-updates"
    echo "Or use manual signing assets: ./scripts/build_app.sh --signing-identity <cert> --main-profile /path/to/main.provisionprofile --sync-profile /path/to/sync.provisionprofile"
  fi
fi
