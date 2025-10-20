#!/usr/bin/env bash
set -euo pipefail

SRC="${1:?usage: make_appiconset.sh <src.png> <dest.appiconset>}"
DEST="${2:?usage: make_appiconset.sh <src.png> <dest.appiconset>}"

mkdir -p "$DEST"

# Ensure square canvas (centered) and PNG with alpha (requires ImageMagick if present).
# If you don't have ImageMagick, comment this block out.
if command -v magick >/dev/null 2>&1; then
  TMP="$(mktemp /tmp/appicon.XXXXXX.png)"
  # Center on a 1024x1024 canvas (keeps aspect, adds transparent padding if needed)
  magick "$SRC" -resize 1024x1024 -background none -gravity center -extent 1024x1024 PNG32:"$TMP"
  SRC="$TMP"
fi

gen() { sips -z "$1" "$1" "$SRC" --out "$DEST/$2" >/dev/null; }

# 1x sizes
gen 16  icon_16x16.png
gen 32  icon_32x32.png
gen 128 icon_128x128.png
gen 256 icon_256x256.png
gen 512 icon_512x512.png

# 2x sizes
gen 32   icon_16x16@2x.png
gen 64   icon_32x32@2x.png
gen 256  icon_128x128@2x.png
gen 512  icon_256x256@2x.png
cp "$SRC" "$DEST/icon_512x512@2x.png"    # 1024x1024

# Contents.json for macOS AppIcon
cat >"$DEST/Contents.json" <<'JSON'
{
  "images" : [
    {"idiom":"mac","size":"16x16","scale":"1x","filename":"icon_16x16.png"},
    {"idiom":"mac","size":"16x16","scale":"2x","filename":"icon_16x16@2x.png"},
    {"idiom":"mac","size":"32x32","scale":"1x","filename":"icon_32x32.png"},
    {"idiom":"mac","size":"32x32","scale":"2x","filename":"icon_32x32@2x.png"},
    {"idiom":"mac","size":"128x128","scale":"1x","filename":"icon_128x128.png"},
    {"idiom":"mac","size":"128x128","scale":"2x","filename":"icon_128x128@2x.png"},
    {"idiom":"mac","size":"256x256","scale":"1x","filename":"icon_256x256.png"},
    {"idiom":"mac","size":"256x256","scale":"2x","filename":"icon_256x256@2x.png"},
    {"idiom":"mac","size":"512x512","scale":"1x","filename":"icon_512x512.png"},
    {"idiom":"mac","size":"512x512","scale":"2x","filename":"icon_512x512@2x.png"}
  ],
  "info" : { "version": 1, "author": "xcode" }
}
JSON

# Optional: also produce a .icns in a sibling folder (useful outside asset catalogs)
ICONSET="$(mktemp -d)/AppIcon.iconset"
cp "$DEST"/icon_*.png "$ICONSET"/
if command -v iconutil >/dev/null 2>&1; then
  iconutil -c icns "$ICONSET" -o "$(dirname "$DEST")/AppIcon.icns"
fi

echo "✅ AppIcon generated at: $DEST"
