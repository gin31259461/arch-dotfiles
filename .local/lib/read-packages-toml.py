#!/usr/bin/env python3
"""Read package group TOML files and emit install-packages.sh records."""

from __future__ import annotations

import sys
import tomllib
from pathlib import Path
from typing import Any


def die(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def require_str(group: dict[str, Any], field: str, source: Path) -> str:
    value = group.get(field)
    if not isinstance(value, str) or not value.strip():
        die(f"{source}: group field '{field}' must be a non-empty string")
    if "\t" in value or "|" in value:
        die(f"{source}: group field '{field}' cannot contain tabs or pipes")
    return value.strip()


def validate_key(key: str, source: Path) -> str:
    if not key.strip():
        die(f"{source}: group table name cannot be empty")
    if "\t" in key or "|" in key:
        die(f"{source}: group table name cannot contain tabs or pipes")
    if any(char.isspace() for char in key):
        die(f"{source}: group table name cannot contain whitespace")
    return key.strip()


def optional_pkg_list(group: dict[str, Any], field: str, source: Path) -> str:
    value = group.get(field, [])
    if value is None:
        return ""
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        die(f"{source}: group field '{field}' must be an array of strings")

    packages: list[str] = []
    for item in value:
        package = item.strip()
        if not package:
            die(f"{source}: group field '{field}' contains an empty package name")
        if any(char.isspace() for char in package):
            die(f"{source}: package '{package}' cannot contain whitespace")
        packages.append(package)

    return " ".join(packages)


def load_file(path: Path) -> dict[str, Any]:
    try:
        data = tomllib.loads(path.read_text(encoding="utf-8"))
    except tomllib.TOMLDecodeError as error:
        die(f"{path}: invalid TOML: {error}")
    except OSError as error:
        die(f"{path}: cannot read file: {error}")

    return data


def main() -> int:
    if len(sys.argv) != 2:
        die("usage: read-packages-toml.py <packages.d>")

    package_dir = Path(sys.argv[1]).expanduser()
    if not package_dir.is_dir():
        die(f"package directory not found: {package_dir}")

    files = sorted(package_dir.glob("*.toml"))
    if not files:
        die(f"no TOML package files found in {package_dir}")

    seen_keys: dict[str, Path] = {}
    for path in files:
        groups = load_file(path)
        if not groups:
            die(f"{path}: expected at least one package group table")

        for key, group in groups.items():
            if not isinstance(group, dict):
                die(f"{path}: [{key}] must be a table")

            key = validate_key(key, path)
            label = require_str(group, "label", path)
            official = optional_pkg_list(group, "official", path)
            aur = optional_pkg_list(group, "aur", path)

            if key in seen_keys:
                die(f"{path}: duplicate group key '{key}' already defined in {seen_keys[key]}")
            seen_keys[key] = path

            print(f"{key}|{label}|{official}|{aur}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
