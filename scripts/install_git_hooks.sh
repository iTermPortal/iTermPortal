#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_HOOK="$REPO_ROOT/.githooks/prepare-commit-msg"
TARGET_HOOK="$REPO_ROOT/.git/hooks/prepare-commit-msg"

if [[ ! -d "$REPO_ROOT/.git" ]]; then
  echo "Not a git repository: $REPO_ROOT" >&2
  exit 1
fi

if [[ ! -f "$SOURCE_HOOK" ]]; then
  echo "Missing hook template: $SOURCE_HOOK" >&2
  exit 1
fi

if [[ -f "$TARGET_HOOK" ]] && ! cmp -s "$SOURCE_HOOK" "$TARGET_HOOK"; then
  cp "$TARGET_HOOK" "$TARGET_HOOK.bak"
  echo "Backed up existing hook to: $TARGET_HOOK.bak"
fi

cp "$SOURCE_HOOK" "$TARGET_HOOK"
chmod +x "$TARGET_HOOK"

echo "Installed prepare-commit-msg hook:"
echo "  $TARGET_HOOK"
