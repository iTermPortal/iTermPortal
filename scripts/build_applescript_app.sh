#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_SCRIPT="$ROOT_DIR/applescript/OpenTerminalHere.applescript"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="fPortal.app"
APP_PATH="$DIST_DIR/$APP_NAME"
LEGACY_APP_PATH="$DIST_DIR/Open Terminal Here.app"
INFO_PLIST="$APP_PATH/Contents/Info.plist"

if [[ ! -f "$SOURCE_SCRIPT" ]]; then
  echo "Missing source script: $SOURCE_SCRIPT" >&2
  exit 1
fi

if ! command -v osacompile >/dev/null 2>&1; then
  echo "osacompile is required and was not found." >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
rm -rf "$LEGACY_APP_PATH"
rm -rf "$APP_PATH"

osacompile -o "$APP_PATH" "$SOURCE_SCRIPT"

/usr/libexec/PlistBuddy -c "Delete :LSUIElement" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$INFO_PLIST"

# Ad-hoc sign avoids Gatekeeper warnings for local builds where possible.
codesign --force --deep --sign - "$APP_PATH" >/dev/null

echo "Built: $APP_PATH"
echo "No Dock icon: LSUIElement=true"
