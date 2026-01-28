#!/usr/bin/env bash
set -euo pipefail

mkdir -p .tmp
# shellcheck disable=SC1091
source .tmp/beads.env

# Ensure Beads workspace exists (.beads)
if $BEADS where >/dev/null 2>&1; then
  echo "Beads workspace found."
else
  echo "No Beads workspace found. Initializing..."
  $BEADS init --stealth
  $BEADS where
fi
