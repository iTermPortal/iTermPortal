#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    version_file = repo_root / "ssmver.toml"
    text = version_file.read_text(encoding="utf-8")

    match = re.search(r'^version\s*=\s*"([^"]+)"\s*$', text, re.MULTILINE)
    if not match:
        print(f"Unable to find version in {version_file}", file=sys.stderr)
        return 1

    print(match.group(1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
