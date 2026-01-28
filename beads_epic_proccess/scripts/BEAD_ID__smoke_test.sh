#!/usr/bin/env bash
set -euo pipefail

# Smoke test template for a bead.
# Copy this file to: scripts/beads/<BEAD_ID>__smoke_test.sh
# Then replace the commands below with repo-appropriate checks.
#
# Goals:
# - Quick to run (< 2 minutes ideally)
# - Deterministic
# - Proves the critical path for this bead
#
# Tips:
# - Prefer a small targeted command over full test suite.
# - Print clear PASS/FAIL markers.

BEAD_ID="${BEAD_ID:-UNKNOWN_BEAD}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "== Smoke test for ${BEAD_ID} =="
echo "Repo root: ${ROOT}"
echo

cd "${ROOT}"

# ----------------------------
# TODO: Replace this section
# ----------------------------
# Example (Node):
#   npm test -- <test-name>
#
# Example (Python):
#   python -m pytest -k "keyword" -q
#
# Example (Go):
#   go test ./... -run TestName -count=1
#
# Example (curl healthcheck):
#   curl -fsS http://127.0.0.1:8080/health | grep -q "ok"

echo "TODO: implement smoke test for this bead"
echo "FAIL (placeholder)"
exit 1
