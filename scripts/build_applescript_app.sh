#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_SCRIPT="$ROOT_DIR/applescript/OpenTerminalHere.applescript"
BASE_SCRIPT="$ROOT_DIR/applescript/OpenTerminalHere.base.applescript"
TERMINAL_SCRIPT_SOURCES=(
  "$ROOT_DIR/applescript/terminals/ITerm2.applescript"
  "$ROOT_DIR/applescript/terminals/Terminal.applescript"
  "$ROOT_DIR/applescript/terminals/Ghostty.applescript"
  "$ROOT_DIR/applescript/terminals/Warp.applescript"
)
HELPER_SOURCE="$ROOT_DIR/swift/ITermPortalStatusBar.swift"
ICON_SOURCE="$ROOT_DIR/assets/icons/negative.png"
APPSTORE_ICON_SOURCE="$ROOT_DIR/assets/icons/input.png"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="iTermPortal.app"
APP_PATH="$DIST_DIR/$APP_NAME"
LEGACY_APP_PATH="$DIST_DIR/Open Terminal Here.app"
INFO_PLIST="$APP_PATH/Contents/Info.plist"
RESOURCES_DIR="$APP_PATH/Contents/Resources"
APP_ICON_PATH="$RESOURCES_DIR/applet.icns"
DROPLET_ICON_PATH="$RESOURCES_DIR/droplet.icns"
BUNDLE_ICON_PATH="$RESOURCES_DIR/AppIcon.icns"
ASSET_CATALOG_PATH="$RESOURCES_DIR/Assets.car"
CUSTOM_ICON_RESOURCE="$APP_PATH/Icon"$'\r'
HELPER_APP_NAME="iTermPortalMenu.app"
HELPER_APP_PATH="$APP_PATH/Contents/Library/LoginItems/$HELPER_APP_NAME"
HELPER_EXECUTABLE_NAME="iTermPortalMenu"
HELPER_EXECUTABLE_PATH="$HELPER_APP_PATH/Contents/MacOS/$HELPER_EXECUTABLE_NAME"
HELPER_INFO_PLIST="$HELPER_APP_PATH/Contents/Info.plist"
BUNDLE_ID="${FPORTAL_BUNDLE_ID:-com.hjoncour.fportal}"
SSMVER_FILE="$ROOT_DIR/ssmver.toml"
TMP_DIR=""

if [[ ! -f "$SSMVER_FILE" ]]; then
  echo "Missing version file: $SSMVER_FILE" >&2
  exit 1
fi

APP_VERSION="$(grep -m1 '^version' "$SSMVER_FILE" | sed 's/.*= *"//;s/"//')"
if [[ -z "$APP_VERSION" ]]; then
  echo "No version found in $SSMVER_FILE" >&2
  exit 1
fi

if [[ ! -f "$BASE_SCRIPT" ]]; then
  echo "Missing base script: $BASE_SCRIPT" >&2
  exit 1
fi

for script_source in "${TERMINAL_SCRIPT_SOURCES[@]}"; do
  if [[ ! -f "$script_source" ]]; then
    echo "Missing terminal script source: $script_source" >&2
    exit 1
  fi
done

if [[ ! -f "$ICON_SOURCE" ]]; then
  echo "Missing icon source: $ICON_SOURCE" >&2
  exit 1
fi

if [[ ! -f "$APPSTORE_ICON_SOURCE" ]]; then
  echo "Missing App Store icon source: $APPSTORE_ICON_SOURCE" >&2
  exit 1
fi

if [[ ! -f "$HELPER_SOURCE" ]]; then
  echo "Missing status bar helper source: $HELPER_SOURCE" >&2
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

if ! command -v swiftc >/dev/null 2>&1; then
  echo "swiftc is required and was not found." >&2
  exit 1
fi

if ! command -v Rez >/dev/null 2>&1; then
  echo "Rez is required and was not found." >&2
  exit 1
fi

if ! command -v DeRez >/dev/null 2>&1; then
  echo "DeRez is required and was not found." >&2
  exit 1
fi

if ! command -v SetFile >/dev/null 2>&1; then
  echo "SetFile is required and was not found." >&2
  exit 1
fi

cleanup() {
  if [[ -n "${TMP_DIR:-}" && -d "${TMP_DIR:-}" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

compose_applescript_source() {
  {
    echo "-- GENERATED FILE: DO NOT EDIT DIRECTLY."
    echo "-- Edit 'applescript/OpenTerminalHere.base.applescript' and files under 'applescript/terminals/'."
    echo ""
    cat "$BASE_SCRIPT"
    for script_source in "${TERMINAL_SCRIPT_SOURCES[@]}"; do
      echo ""
      echo "-- >>> $(basename "$script_source")"
      cat "$script_source"
    done
  } > "$SOURCE_SCRIPT"
}

mkdir -p "$DIST_DIR"
rm -rf "$LEGACY_APP_PATH"
rm -rf "$APP_PATH"

compose_applescript_source
osacompile -o "$APP_PATH" "$SOURCE_SCRIPT"

TMP_DIR="$(mktemp -d "$DIST_DIR/.iconbuild.XXXXXX")"
ICONSET_DIR="$TMP_DIR/iTermPortal.iconset"
mkdir -p "$ICONSET_DIR"

# Use negative.png for all installed-app icon sizes; input.png for the 1024px
# App Store listing icon (icon_512x512@2x.png).
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
EOF
sips -z 1024 1024 "$APPSTORE_ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null

GENERATED_ICON_PATH="$TMP_DIR/iTermPortal.icns"
iconutil -c icns "$ICONSET_DIR" -o "$GENERATED_ICON_PATH"
cp "$GENERATED_ICON_PATH" "$APP_ICON_PATH"
cp "$GENERATED_ICON_PATH" "$DROPLET_ICON_PATH"
cp "$GENERATED_ICON_PATH" "$BUNDLE_ICON_PATH"
rm -f "$ASSET_CATALOG_PATH"

rm -rf "$HELPER_APP_PATH"
mkdir -p "$HELPER_APP_PATH/Contents/MacOS" "$HELPER_APP_PATH/Contents/Resources"

swiftc -O -framework AppKit "$HELPER_SOURCE" -o "$HELPER_EXECUTABLE_PATH"
chmod +x "$HELPER_EXECUTABLE_PATH"
cp "$GENERATED_ICON_PATH" "$HELPER_APP_PATH/Contents/Resources/AppIcon.icns"

cat > "$HELPER_INFO_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$HELPER_EXECUTABLE_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon.icns</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}.menu</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>iTermPortal Menu</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$HELPER_APP_PATH" >/dev/null

/usr/libexec/PlistBuddy -c "Delete :LSUIElement" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon.icns" "$INFO_PLIST"
# Fix CFBundleDocumentTypes: osacompile creates entries missing CFBundleTypeName (required by App Store).
/usr/libexec/PlistBuddy -c "Delete :CFBundleDocumentTypes" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes array" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0 dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:CFBundleTypeName string Folder" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Viewer" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:CFBundleTypeIconFile string AppIcon.icns" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSHandlerRank string Alternate" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes array" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:0 string public.folder" "$INFO_PLIST"
# App Store required keys.
/usr/libexec/PlistBuddy -c "Delete :LSApplicationCategoryType" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :LSApplicationCategoryType string public.app-category.developer-tools" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Delete :LSMinimumSystemVersion" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 11.0" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Delete :CFBundleVersion" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Delete :CFBundleShortVersionString" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $(date +%Y%m%d%H%M%S)" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $APP_VERSION" "$INFO_PLIST"
if /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$INFO_PLIST"
else
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$INFO_PLIST"
fi

# AppleScript applets can still show the default Script Editor icon unless the
# bundle itself has a custom icon resource at its root.
CUSTOM_ICON_REZ="$TMP_DIR/custom-icon.r"
CUSTOM_ICON_SOURCE="$TMP_DIR/custom-icon-source.png"
cp "$ICON_SOURCE" "$CUSTOM_ICON_SOURCE"
sips -i "$CUSTOM_ICON_SOURCE" >/dev/null
DeRez -only icns "$CUSTOM_ICON_SOURCE" > "$CUSTOM_ICON_REZ"
rm -f "$CUSTOM_ICON_RESOURCE"
Rez -append "$CUSTOM_ICON_REZ" -o "$CUSTOM_ICON_RESOURCE" >/dev/null
SetFile -a C "$APP_PATH"
SetFile -a V "$CUSTOM_ICON_RESOURCE"
touch "$APP_PATH"

# Clear xattrs (resource forks, FinderInfo) that codesign rejects, then
# ad-hoc sign as the very last step.  Any bundle modification after signing
# invalidates the signature and causes macOS to silently block Apple Events.
xattr -cr "$APP_PATH"
codesign --force --deep --sign - "$APP_PATH" >/dev/null

echo "Built: $APP_PATH"
echo "No Dock icon: LSUIElement=true"
echo "Icon source: $ICON_SOURCE"
echo "Bundle ID: $BUNDLE_ID"
echo "Status bar helper: $HELPER_APP_PATH"
