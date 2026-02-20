#!/usr/bin/env python3
"""
Automatic version bumping for fPortal.

Version format:
    major.feature.fix

Commit message prefixes:
    release(...): ... or major(...): ... -> major bump
    feature(...): ...                    -> feature bump
    fix(...): ...                        -> fix bump
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


def parse_version(version: str) -> tuple[int, int, int]:
    match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", version.strip())
    if not match:
        raise ValueError(f"Invalid version format: {version}")
    major, feature, fix = match.groups()
    return int(major), int(feature), int(fix)


def infer_bump_type(commit_message: str) -> str | None:
    first_line = commit_message.strip().lower()
    if first_line.startswith("release(") or first_line.startswith("major("):
        return "major"
    if first_line.startswith("feature("):
        return "feature"
    if first_line.startswith("fix("):
        return "fix"
    return None


def bump_version(version: str, bump_type: str) -> str:
    major, feature, fix = parse_version(version)
    if bump_type == "major":
        return f"{major + 1}.0.0"
    if bump_type == "feature":
        return f"{major}.{feature + 1}.0"
    if bump_type == "fix":
        return f"{major}.{feature}.{fix + 1}"
    return version


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: bump_version.py <commit_message> [base_version]", file=sys.stderr)
        return 1

    commit_message = sys.argv[1]
    base_version = sys.argv[2] if len(sys.argv) > 2 else None

    bump_type = infer_bump_type(commit_message)
    if not bump_type:
        return 0

    repo_root = Path(__file__).resolve().parent.parent
    version_file = repo_root / "config" / "VERSION"

    if not version_file.exists():
        print(f"Missing VERSION file: {version_file}", file=sys.stderr)
        return 1

    current_version = version_file.read_text(encoding="utf-8").strip()
    source_version = base_version.strip() if base_version else current_version
    new_version = bump_version(source_version, bump_type)

    if new_version == current_version:
        print(f"No version change: {current_version}")
        return 0

    version_file.write_text(f"{new_version}\n", encoding="utf-8")
    print(f"Version bumped: {source_version} -> {new_version} ({bump_type})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
