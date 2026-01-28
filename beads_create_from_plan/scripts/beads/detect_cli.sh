#!/usr/bin/env bash
set -euo pipefail

# Detect which Beads CLI binary exists. Prefer "br", fallback to "bd".
mkdir -p .tmp

if command -v bd >/dev/null 2>&1; then
  echo "BEADS=bd" > .tmp/beads.env
  echo "Using Beads CLI: bd"
else
  echo "ERROR: Beads CLI not found (br/bd). Install beads first." >&2
  exit 1
fi
