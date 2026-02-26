#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="iTermPortal.app"
SOURCE_APP="$ROOT_DIR/dist/$APP_NAME"
DEST_DIR="/Applications"
DEST_APP="$DEST_DIR/$APP_NAME"

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

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "Missing built app: $SOURCE_APP" >&2
  echo "Build first with: sh scripts/build_applescript_app.sh" >&2
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
