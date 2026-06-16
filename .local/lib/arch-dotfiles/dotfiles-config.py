#!/usr/bin/env python3
"""Central TOML reader for dotfile management scripts."""

from __future__ import annotations

import argparse
import sys
import tomllib
from pathlib import Path
from typing import Any


Record = list[str]


def die(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def reject_pipe(value: str, source: Path, field: str) -> None:
    if "|" in value:
        die(f"{source}: {field} cannot contain pipes")


def load_toml(path: Path) -> dict[str, Any]:
    try:
        return tomllib.loads(path.read_text(encoding="utf-8"))
    except tomllib.TOMLDecodeError as error:
        die(f"{path}: invalid TOML: {error}")
    except OSError as error:
        die(f"{path}: cannot read file: {error}")


def validate_key(key: str, source: Path, kind: str) -> str:
    if not key.strip():
        die(f"{source}: {kind} table name cannot be empty")
    if "|" in key or any(char.isspace() for char in key):
        die(f"{source}: {kind} table name cannot contain pipes or whitespace")
    return key.strip()


def require_table(data: Any, source: Path, key: str) -> dict[str, Any]:
    if not isinstance(data, dict):
        die(f"{source}: [{key}] must be a table")
    return data


def require_str(config: dict[str, Any], field: str, source: Path, key: str) -> str:
    value = config.get(field)
    if not isinstance(value, str) or not value.strip():
        die(f"{source}: [{key}].{field} must be a non-empty string")
    reject_pipe(value, source, f"[{key}].{field}")
    return value.strip()


def optional_str(config: dict[str, Any], field: str, source: Path, key: str) -> str:
    value = config.get(field, "")
    if value is None:
        return ""
    if not isinstance(value, str):
        die(f"{source}: [{key}].{field} must be a string")
    reject_pipe(value, source, f"[{key}].{field}")
    return value.strip()


def optional_bool(config: dict[str, Any], field: str, source: Path, key: str) -> str:
    value = config.get(field, False)
    if not isinstance(value, bool):
        die(f"{source}: [{key}].{field} must be a boolean")
    return "true" if value else "false"


def optional_pkg_list(config: dict[str, Any], field: str, source: Path, key: str) -> str:
    value = config.get(field, [])
    if value is None:
        return ""
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        die(f"{source}: [{key}].{field} must be an array of strings")

    packages: list[str] = []
    for item in value:
        package = item.strip()
        if not package:
            die(f"{source}: [{key}].{field} contains an empty package name")
        if any(char.isspace() for char in package):
            die(f"{source}: package '{package}' cannot contain whitespace")
        packages.append(package)

    return " ".join(packages)


def emit(records: list[Record]) -> None:
    for record in records:
        print("|".join(record))


def package_records(package_dir: Path) -> list[Record]:
    if not package_dir.is_dir():
        die(f"package directory not found: {package_dir}")

    files = sorted(package_dir.glob("*.toml"))
    if not files:
        die(f"no TOML package files found in {package_dir}")

    seen_keys: dict[str, Path] = {}
    records: list[Record] = []

    for path in files:
        groups = load_toml(path)
        if not groups:
            die(f"{path}: expected at least one package group table")

        for raw_key, raw_group in groups.items():
            key = validate_key(raw_key, path, "package group")
            group = require_table(raw_group, path, key)
            label = require_str(group, "label", path, key)
            official = optional_pkg_list(group, "official", path, key)
            aur = optional_pkg_list(group, "aur", path, key)

            if key in seen_keys:
                die(f"{path}: duplicate group key '{key}' already defined in {seen_keys[key]}")
            seen_keys[key] = path
            records.append([key, label, official, aur])

    return records


def cleanup_records(config_path: Path) -> list[Record]:
    data = load_toml(config_path)
    if not data:
        die(f"{config_path}: expected at least one cleanup task table")

    records: list[Record] = []
    for raw_key, raw_config in data.items():
        key = validate_key(raw_key, config_path, "cleanup task")
        config = require_table(raw_config, config_path, key)
        label = require_str(config, "label", config_path, key)
        detail = require_str(config, "detail", config_path, key)
        requires = optional_str(config, "requires", config_path, key)
        sudo = optional_bool(config, "sudo", config_path, key)
        records.append([key, label, detail, requires, sudo])

    return records


def dotfile_paths(config_path: Path) -> list[Record]:
    data = load_toml(config_path)
    seen: set[str] = set()
    records: list[Record] = []

    for group, raw_config in data.items():
        config = require_table(raw_config, config_path, group)
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
                records.append([path])
                seen.add(path)

    return records


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    packages = subparsers.add_parser("packages", help="emit package group records")
    packages.add_argument("path", type=Path, help="config/packages.d directory")

    cleanup = subparsers.add_parser("cleanup", help="emit cleanup task records")
    cleanup.add_argument("path", type=Path, help="config/cleanup.toml file")

    dotfiles = subparsers.add_parser("dotfiles", help="emit tracked dotfile paths")
    dotfiles.add_argument("path", type=Path, help="config/dotfiles.toml file")

    args = parser.parse_args()
    path = args.path.expanduser()

    if args.command == "packages":
        emit(package_records(path))
    elif args.command == "cleanup":
        emit(cleanup_records(path))
    elif args.command == "dotfiles":
        emit(dotfile_paths(path))
    else:
        die(f"unknown command: {args.command}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
