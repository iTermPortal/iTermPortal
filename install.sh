#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="iTermPortal.app"
SOURCE_APP="$ROOT_DIR/dist/$APP_NAME"
FALLBACK_SOURCE_APP="$ROOT_DIR/build/DerivedData/Build/Products/Debug/$APP_NAME"
DEST_DIR="/Applications"
CONFIGURATION="${FPORTAL_CONFIGURATION:-Debug}"
DERIVED_DATA_PATH="${FPORTAL_DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedData}"
DEVELOPMENT_TEAM="${FPORTAL_DEVELOPMENT_TEAM:-}"
ALLOW_PROVISIONING_UPDATES=0
SIGNING_IDENTITY="${FPORTAL_SIGNING_IDENTITY:-}"
MAIN_PROVISIONING_PROFILE="${FPORTAL_MAIN_PROVISIONING_PROFILE:-}"
SYNC_PROVISIONING_PROFILE="${FPORTAL_SYNC_PROVISIONING_PROFILE:-}"
SKIP_BUILD=0
CURRENT_EXTENSION_ID="com.hjoncour.fPortal.FinderExtension"
LEGACY_EXTENSION_ID="hjoncour.fPortal.fPortalExtension"
LEGACY_APP_PATH="$HOME/Applications/fPortal.app"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Build and install the native iTermPortal app.

Options:
  --configuration <name>  Xcode build configuration (default: Debug)
  --development-team <id> Use Apple Development signing for Finder Sync
  --dest <path>           Install destination directory (default: /Applications)
  --allow-provisioning-updates
                          Let xcodebuild create/download development profiles
  --signing-identity <id> Manually sign the built app with this certificate
  --main-profile <path>   Provisioning profile for com.hjoncour.fPortal
  --sync-profile <path>   Provisioning profile for com.hjoncour.fPortal.FinderExtension
  --skip-build            Install the latest built app without rebuilding
  -h, --help              Show this help
EOF
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
    --dest)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      DEST_DIR="$2"
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
    --skip-build)
      SKIP_BUILD=1
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

DEST_APP="$DEST_DIR/$APP_NAME"
SOURCE_APP="$ROOT_DIR/dist/$APP_NAME"
FALLBACK_SOURCE_APP="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME"

run_maybe_sudo() {
  if "$@"; then
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    echo "Retrying with sudo: $*"
    sudo "$@"
    return 0
  fi

  return 1
}

refresh_finder_extensions() {
  if ! command -v pluginkit >/dev/null 2>&1; then
    return 0
  fi

  python3 - <<PY || true
import plistlib
from pathlib import Path

plist_path = Path.home() / "Library/Preferences/com.apple.finder.plist"
if not plist_path.exists():
    raise SystemExit(0)

with plist_path.open("rb") as handle:
    data = plistlib.load(handle)

legacy = "${LEGACY_EXTENSION_ID}"
current = "${CURRENT_EXTENSION_ID}"
blocked_app_markers = [
    "fPortal.app",
    "iTermPortal.app",
    "${ROOT_DIR}/dist/${APP_NAME}",
    "${ROOT_DIR}/build/DerivedData/Build/Products/Debug/${APP_NAME}",
    "${HOME}/Applications/fPortal.app",
]

auto = list(data.get("FXSyncExtensionToolbarItemsAutomaticallyAdded", []))
pending_add = list(data.get("FXSyncExtensionToolbarItemsPendingAdd", []))
pending_remove = list(data.get("FXSyncExtensionToolbarItemsPendingRemove", []))
toolbar = dict(data.get("NSToolbar Configuration Browser", {}))
default_identifiers = list(toolbar.get("TB Default Item Identifiers", []))
item_identifiers = list(toolbar.get("TB Item Identifiers", []))
item_plists = dict(toolbar.get("TB Item Plists", {}))

auto = [item for item in auto if item != legacy]
if current not in auto:
    auto.append(current)
if current in pending_remove:
    pending_remove = [item for item in pending_remove if item != current]
if current not in pending_add:
    pending_add.append(current)
if legacy not in pending_remove:
    pending_remove.append(legacy)

def ensure_toolbar_identifier(items):
    if current in items:
        return items

    try:
        insert_at = items.index("com.apple.finder.SRCH")
    except ValueError:
        insert_at = len(items)

    items.insert(insert_at, current)
    return items

default_identifiers = ensure_toolbar_identifier(default_identifiers)
item_identifiers = [item for item in item_identifiers if item != legacy]
item_identifiers = ensure_toolbar_identifier(item_identifiers)

filtered_item_plists = {}
for key, value in item_plists.items():
    url_string = str(value.get("_CFURLString", ""))
    alias_data = value.get("_CFURLAliasData", b"")
    if isinstance(alias_data, bytes):
        alias_text = alias_data.decode("utf-8", "ignore")
    else:
        alias_text = str(alias_data)

    if any(marker in url_string or marker in alias_text for marker in blocked_app_markers):
        continue

    filtered_item_plists[key] = value

data["FXSyncExtensionToolbarItemsAutomaticallyAdded"] = auto
data["FXSyncExtensionToolbarItemsPendingAdd"] = pending_add
data["FXSyncExtensionToolbarItemsPendingRemove"] = pending_remove
toolbar["TB Default Item Identifiers"] = default_identifiers
toolbar["TB Item Identifiers"] = item_identifiers
toolbar["TB Item Plists"] = filtered_item_plists
data["NSToolbar Configuration Browser"] = toolbar

with plist_path.open("wb") as handle:
    plistlib.dump(data, handle)
PY

  if pluginkit -m -A -D 2>/dev/null | grep -Fq "$LEGACY_EXTENSION_ID"; then
    echo "Disabling legacy Finder extension: $LEGACY_EXTENSION_ID"
    pluginkit -e ignore -i "$LEGACY_EXTENSION_ID" || true
  fi

  echo "Enabling Finder extension: $CURRENT_EXTENSION_ID"
  pluginkit -e use -i "$CURRENT_EXTENSION_ID" || true

  if pgrep cfprefsd >/dev/null 2>&1; then
    killall cfprefsd || true
  fi

  if pgrep Finder >/dev/null 2>&1; then
    echo "Restarting Finder to refresh toolbar extensions..."
    killall Finder || true
  fi

  if [[ -d "$LEGACY_APP_PATH" ]]; then
    echo "Note: legacy app still exists at $LEGACY_APP_PATH"
    echo "It is no longer enabled, but you may want to delete it manually to avoid confusion."
  fi
}

stop_stale_menu_bar_apps() {
  local stale_paths=(
    "$ROOT_DIR/dist/$APP_NAME/Contents/MacOS/iTermPortal"
    "$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME/Contents/MacOS/iTermPortal"
    "$HOME/Applications/fPortal.app/Contents/MacOS/fPortal"
  )

  for stale_path in "${stale_paths[@]}"; do
    if pgrep -f "$stale_path" >/dev/null 2>&1; then
      echo "Stopping stale app instance: $stale_path"
      pkill -f "$stale_path" || true
    fi
  done
}

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  build_args=(
    --configuration "$CONFIGURATION"
    --derived-data "$DERIVED_DATA_PATH"
  )

  if [[ -n "$DEVELOPMENT_TEAM" ]]; then
    build_args+=(--development-team "$DEVELOPMENT_TEAM")
  fi

  if [[ -n "$SIGNING_IDENTITY" ]]; then
    build_args+=(--signing-identity "$SIGNING_IDENTITY")
  fi

  if [[ -n "$MAIN_PROVISIONING_PROFILE" ]]; then
    build_args+=(--main-profile "$MAIN_PROVISIONING_PROFILE")
  fi

  if [[ -n "$SYNC_PROVISIONING_PROFILE" ]]; then
    build_args+=(--sync-profile "$SYNC_PROVISIONING_PROFILE")
  fi

  if [[ "$ALLOW_PROVISIONING_UPDATES" -eq 1 ]]; then
    build_args+=(--allow-provisioning-updates)
  fi

  "$ROOT_DIR/scripts/build_app.sh" "${build_args[@]}"
fi

if [[ ! -d "$SOURCE_APP" && -d "$FALLBACK_SOURCE_APP" ]]; then
  SOURCE_APP="$FALLBACK_SOURCE_APP"
fi

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "Missing built app: $SOURCE_APP" >&2
  echo "Build first with: ./scripts/build_app.sh" >&2
  exit 1
fi

echo "Installing $APP_NAME to $DEST_DIR..."

run_maybe_sudo mkdir -p "$DEST_DIR"

if [[ -e "$DEST_APP" ]]; then
  echo "Removing existing install: $DEST_APP"
  run_maybe_sudo rm -rf "$DEST_APP"
fi

run_maybe_sudo ditto "$SOURCE_APP" "$DEST_APP"

refresh_finder_extensions
stop_stale_menu_bar_apps

echo "Installed: $DEST_APP"
