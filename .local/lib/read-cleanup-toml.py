#!/usr/bin/env python3
"""Read cleanup task TOML and emit cleanup.sh records."""

from __future__ import annotations

import sys
import tomllib
from pathlib import Path
from typing import Any


def die(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def require_str(config: dict[str, Any], field: str, source: Path, key: str) -> str:
    value = config.get(field)
    if not isinstance(value, str) or not value.strip():
        die(f"{source}: [{key}].{field} must be a non-empty string")
    if "|" in value:
        die(f"{source}: [{key}].{field} cannot contain pipes")
    return value.strip()


def optional_str(config: dict[str, Any], field: str, source: Path, key: str) -> str:
    value = config.get(field, "")
    if value is None:
        return ""
    if not isinstance(value, str):
        die(f"{source}: [{key}].{field} must be a string")
    if "|" in value:
        die(f"{source}: [{key}].{field} cannot contain pipes")
    return value.strip()


def optional_bool(config: dict[str, Any], field: str, source: Path, key: str) -> str:
    value = config.get(field, False)
    if not isinstance(value, bool):
        die(f"{source}: [{key}].{field} must be a boolean")
    return "true" if value else "false"


def validate_key(key: str, source: Path) -> str:
    if not key.strip():
        die(f"{source}: task table name cannot be empty")
    if "|" in key or any(char.isspace() for char in key):
        die(f"{source}: task table name cannot contain pipes or whitespace")
    return key.strip()


def load_config(path: Path) -> dict[str, Any]:
    try:
        return tomllib.loads(path.read_text(encoding="utf-8"))
    except tomllib.TOMLDecodeError as error:
        die(f"{path}: invalid TOML: {error}")
    except OSError as error:
        die(f"{path}: cannot read file: {error}")


def main() -> int:
    if len(sys.argv) != 2:
        die("usage: read-cleanup-toml.py <cleanup.toml>")

    config_path = Path(sys.argv[1]).expanduser()
    data = load_config(config_path)
    if not data:
        die(f"{config_path}: expected at least one cleanup task table")

    for key, config in data.items():
        if not isinstance(config, dict):
            die(f"{config_path}: [{key}] must be a table")

        key = validate_key(key, config_path)
        label = require_str(config, "label", config_path, key)
        detail = require_str(config, "detail", config_path, key)
        requires = optional_str(config, "requires", config_path, key)
        sudo = optional_bool(config, "sudo", config_path, key)
        print(f"{key}|{label}|{detail}|{requires}|{sudo}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
