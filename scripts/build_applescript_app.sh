#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_SCRIPT="$ROOT_DIR/applescript/OpenTerminalHere.applescript"
ICON_SOURCE="$ROOT_DIR/assets/icons/negative.png"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="fPortal.app"
APP_PATH="$DIST_DIR/$APP_NAME"
LEGACY_APP_PATH="$DIST_DIR/Open Terminal Here.app"
INFO_PLIST="$APP_PATH/Contents/Info.plist"
RESOURCES_DIR="$APP_PATH/Contents/Resources"
APP_ICON_PATH="$RESOURCES_DIR/applet.icns"
DROPLET_ICON_PATH="$RESOURCES_DIR/droplet.icns"
TMP_DIR=""

if [[ ! -f "$SOURCE_SCRIPT" ]]; then
  echo "Missing source script: $SOURCE_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$ICON_SOURCE" ]]; then
  echo "Missing icon source: $ICON_SOURCE" >&2
  exit 1
fi

if ! command -v osacompile >/dev/null 2>&1; then
  echo "osacompile is required and was not found." >&2
  exit 1
fi

if ! command -v sips >/dev/null 2>&1; then
  echo "sips is required and was not found." >&2
  exit 1
fi

if ! command -v iconutil >/dev/null 2>&1; then
  echo "iconutil is required and was not found." >&2
  exit 1
fi

cleanup() {
  if [[ -n "${TMP_DIR:-}" && -d "${TMP_DIR:-}" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

mkdir -p "$DIST_DIR"
rm -rf "$LEGACY_APP_PATH"
rm -rf "$APP_PATH"

osacompile -o "$APP_PATH" "$SOURCE_SCRIPT"

TMP_DIR="$(mktemp -d "$DIST_DIR/.iconbuild.XXXXXX")"
ICONSET_DIR="$TMP_DIR/fPortal.iconset"
mkdir -p "$ICONSET_DIR"

while read -r size iconName; do
  sips -z "$size" "$size" "$ICON_SOURCE" --out "$ICONSET_DIR/$iconName" >/dev/null
done <<'EOF'
16 icon_16x16.png
32 icon_16x16@2x.png
32 icon_32x32.png
64 icon_32x32@2x.png
128 icon_128x128.png
256 icon_128x128@2x.png
256 icon_256x256.png
512 icon_256x256@2x.png
512 icon_512x512.png
1024 icon_512x512@2x.png
EOF

GENERATED_ICON_PATH="$TMP_DIR/fPortal.icns"
iconutil -c icns "$ICONSET_DIR" -o "$GENERATED_ICON_PATH"
cp "$GENERATED_ICON_PATH" "$APP_ICON_PATH"
cp "$GENERATED_ICON_PATH" "$DROPLET_ICON_PATH"

/usr/libexec/PlistBuddy -c "Delete :LSUIElement" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string droplet.icns" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Delete :CFBundleVersion" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Delete :CFBundleShortVersionString" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $(date +%Y%m%d%H%M%S)" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0" "$INFO_PLIST"

# Ad-hoc sign avoids Gatekeeper warnings for local builds where possible.
codesign --force --deep --sign - "$APP_PATH" >/dev/null

echo "Built: $APP_PATH"
echo "No Dock icon: LSUIElement=true"
echo "Icon source: $ICON_SOURCE"
