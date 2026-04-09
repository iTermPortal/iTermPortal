#!/usr/bin/env bash
set -euo pipefail

: "${TAP_PATH:?TAP_PATH is required}"
: "${RELEASE_VERSION:?RELEASE_VERSION is required}"
: "${RELEASE_SHA256:?RELEASE_SHA256 is required}"
: "${RELEASE_ASSET_NAME:?RELEASE_ASSET_NAME is required}"
: "${SOURCE_REPOSITORY:?SOURCE_REPOSITORY is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_PATH="${TEMPLATE_PATH:-$ROOT_DIR/packaging/homebrew/Casks/itermportal.rb.template}"
CASK_DIR="$TAP_PATH/Casks"
CASK_PATH="$CASK_DIR/itermportal.rb"
COMMIT_NAME="${TAP_COMMIT_NAME:-github-actions[bot]}"
COMMIT_EMAIL="${TAP_COMMIT_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"
TAP_BRANCH="${TAP_BRANCH:-$(git -C "$TAP_PATH" rev-parse --abbrev-ref HEAD)}"

if [[ "$TAP_BRANCH" == "HEAD" ]]; then
  REMOTE_HEAD="$(git -C "$TAP_PATH" symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [[ -n "$REMOTE_HEAD" ]]; then
    TAP_BRANCH="${REMOTE_HEAD#refs/remotes/origin/}"
  fi
fi

if [[ ! -f "$TEMPLATE_PATH" ]]; then
  echo "Missing cask template: $TEMPLATE_PATH" >&2
  exit 1
fi

if [[ "$TAP_BRANCH" == "HEAD" ]]; then
  echo "Tap repository is in detached HEAD state; set TAP_BRANCH explicitly." >&2
  exit 1
fi

mkdir -p "$CASK_DIR"

python3 "$ROOT_DIR/scripts/render_homebrew_cask.py" \
  --template "$TEMPLATE_PATH" \
  --output "$CASK_PATH" \
  --version "$RELEASE_VERSION" \
  --sha256 "$RELEASE_SHA256" \
  --repository "$SOURCE_REPOSITORY" \
  --asset-name "$RELEASE_ASSET_NAME"

ruby -c "$CASK_PATH"

git -C "$TAP_PATH" config user.name "$COMMIT_NAME"
git -C "$TAP_PATH" config user.email "$COMMIT_EMAIL"

if [[ -z "$(git -C "$TAP_PATH" status --short -- "$CASK_PATH")" ]]; then
  echo "Homebrew tap is already up to date."
  exit 0
fi

git -C "$TAP_PATH" add "$CASK_PATH"
git -C "$TAP_PATH" commit -m "itermportal ${RELEASE_VERSION}"
git -C "$TAP_PATH" push origin "HEAD:${TAP_BRANCH}"

echo "Updated Homebrew tap: $CASK_PATH"
