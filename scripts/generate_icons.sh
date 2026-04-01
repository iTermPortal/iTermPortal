#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON="$ROOT_DIR/assets/icons/negative.png"
APPSTORE="$ROOT_DIR/assets/icons/input.png"
OUT="$ROOT_DIR/Resources/iTermPortal/Assets.xcassets/AppIcon.appiconset"

mkdir -p "$OUT"

while read -r size name; do
  sips -z "$size" "$size" "$ICON" --out "$OUT/$name" >/dev/null
done <<'EOF'
16   icon_16x16.png
32   icon_16x16@2x.png
32   icon_32x32.png
64   icon_32x32@2x.png
128  icon_128x128.png
256  icon_128x128@2x.png
256  icon_256x256.png
512  icon_256x256@2x.png
512  icon_512x512.png
EOF

sips -z 1024 1024 "$APPSTORE" --out "$OUT/icon_512x512@2x.png" >/dev/null

echo "Generated AppIcon assets in $OUT"
