#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="iTermPortal.app"
SOURCE_APP="$ROOT_DIR/dist/$APP_NAME"
FALLBACK_SOURCE_APP="$ROOT_DIR/build/DerivedData/Build/Products/Debug/$APP_NAME"
DEST_DIR="/Applications"
CONFIGURATION="${FPORTAL_CONFIGURATION:-Debug}"
DERIVED_DATA_PATH="${FPORTAL_DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedData}"
SKIP_BUILD=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Build and install the native iTermPortal app.

Options:
  --configuration <name>  Xcode build configuration (default: Debug)
  --dest <path>           Install destination directory (default: /Applications)
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
    --dest)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      DEST_DIR="$2"
      shift 2
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

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  "$ROOT_DIR/scripts/build_app.sh" \
    --configuration "$CONFIGURATION" \
    --derived-data "$DERIVED_DATA_PATH"
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

echo "Installed: $DEST_APP"
