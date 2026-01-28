#!/usr/bin/env bash
set -euo pipefail

mkdir -p .tmp
# shellcheck disable=SC1091
source .tmp/beads.env

echo "== Lint =="
$BEADS lint || true

echo
echo "== List (top) =="
$BEADS list || true

echo
echo "== Ready =="
$BEADS ready || true

echo
echo "== Blocked =="
$BEADS blocked || true

echo
echo "== Where =="
$BEADS where || true
