#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/iTermPortal.xcodeproj"
SCHEME="iTermPortal"
CONFIGURATION="${FPORTAL_CONFIGURATION:-Debug}"
DERIVED_DATA_PATH="${FPORTAL_DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedData}"
DIST_DIR="$ROOT_DIR/dist"
DIST_APP_PATH="$DIST_DIR/iTermPortal.app"
COPY_TO_DIST=1

usage() {
  cat <<'EOF'
Usage: ./scripts/build_app.sh [options]

Build the native iTermPortal macOS app from the Xcode project.

Options:
  --configuration <name>  Xcode build configuration (default: Debug)
  --derived-data <path>   DerivedData output path (default: build/DerivedData)
  --no-copy-to-dist       Leave the built app inside DerivedData only
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
    --derived-data)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      DERIVED_DATA_PATH="$2"
      shift 2
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

mkdir -p "$DIST_DIR"

echo "Building iTermPortal ($CONFIGURATION)..."

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

BUILT_APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/iTermPortal.app"

if [[ ! -d "$BUILT_APP_PATH" ]]; then
  echo "Build completed but app bundle was not found: $BUILT_APP_PATH" >&2
  exit 1
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
