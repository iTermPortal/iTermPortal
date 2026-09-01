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

if [[ -d "$DEST_APP" && ! -L "$DEST_APP" ]]; then
  # Finder toolbar items retain a bookmark to the app bundle itself. Updating
  # the contents in place preserves that bundle's filesystem identity, while
  # deleting and recreating it can turn the toolbar item into a question mark.
  echo "Updating existing install in place: $DEST_APP"
  run_maybe_sudo ditto "$SOURCE_APP" "$DEST_APP"

  if ! codesign --verify --deep --strict "$DEST_APP" >/dev/null 2>&1; then
    echo "In-place update left an invalid bundle; replacing it with a clean copy."
    run_maybe_sudo rm -rf "$DEST_APP"
    run_maybe_sudo ditto "$SOURCE_APP" "$DEST_APP"
  fi
else
  if [[ -e "$DEST_APP" || -L "$DEST_APP" ]]; then
    echo "Replacing non-directory install: $DEST_APP"
    run_maybe_sudo rm -rf "$DEST_APP"
  fi
  run_maybe_sudo ditto "$SOURCE_APP" "$DEST_APP"
fi

codesign --verify --deep --strict "$DEST_APP"

echo "Installed: $DEST_APP"
echo "Finder toolbar: Command-drag $DEST_APP into the toolbar."
echo "If an old item is a question mark, Command-drag it out first."
