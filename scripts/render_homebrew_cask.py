#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Render the Homebrew cask file.")
    parser.add_argument("--template", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--version", required=True)
    parser.add_argument("--sha256", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--asset-name", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    template = args.template.read_text(encoding="utf-8")
    rendered = (
        template.replace("__VERSION__", args.version)
        .replace("__SHA256__", args.sha256)
        .replace("__REPOSITORY__", args.repository)
        .replace("__ASSET_NAME__", args.asset_name)
    )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
