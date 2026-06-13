#!/usr/bin/env python3
"""Read dotfiles staging TOML and emit one path per line."""

from __future__ import annotations

import sys
import tomllib
from pathlib import Path
from typing import Any


def die(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_config(path: Path) -> dict[str, Any]:
    try:
        return tomllib.loads(path.read_text(encoding="utf-8"))
    except tomllib.TOMLDecodeError as error:
        die(f"{path}: invalid TOML: {error}")
    except OSError as error:
        die(f"{path}: cannot read file: {error}")


def main() -> int:
    if len(sys.argv) != 2:
        die("usage: read-dotfiles-toml.py <dotfiles.toml>")

    config_path = Path(sys.argv[1]).expanduser()
    data = load_config(config_path)
    seen: set[str] = set()

    for group, config in data.items():
        if not isinstance(config, dict):
            die(f"{config_path}: [{group}] must be a table")

        paths = config.get("paths")
        if not isinstance(paths, list) or not all(isinstance(item, str) for item in paths):
            die(f"{config_path}: [{group}].paths must be an array of strings")

        for item in paths:
            path = item.strip()
            if not path:
                die(f"{config_path}: [{group}].paths contains an empty path")
            if "\0" in path:
                die(f"{config_path}: [{group}].paths contains a NUL byte")
            if path not in seen:
                print(path)
                seen.add(path)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
