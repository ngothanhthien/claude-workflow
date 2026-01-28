#!/usr/bin/env bash
set -euo pipefail

mkdir -p .tmp
# shellcheck disable=SC1091
source .tmp/beads.env

PLAN_JSON="beads-plan.json"
CREATED_JSON=".tmp/beads-created.json"

if [ ! -f "$PLAN_JSON" ]; then
  echo "ERROR: $PLAN_JSON not found." >&2
  exit 1
fi
if [ ! -f "$CREATED_JSON" ]; then
  echo "ERROR: $CREATED_JSON not found. Run create_issues_from_json.sh first." >&2
  exit 1
fi

python - <<'PY'
import json, subprocess, shlex, pathlib, sys

beads = open(".tmp/beads.env","r",encoding="utf-8").read().strip().split("=",1)[1]
plan = json.loads(pathlib.Path("beads-plan.json").read_text(encoding="utf-8"))
created = json.loads(pathlib.Path(".tmp/beads-created.json").read_text(encoding="utf-8"))

ref_to_id = {t["ref"]: t["id"] for t in created.get("tasks", [])}

def run(cmd):
    print("+", " ".join(shlex.quote(c) for c in cmd))
    subprocess.run(cmd, check=True)

deps_count = 0
for ei, epic in enumerate(plan.get("epics", []), start=1):
    for ti, task in enumerate(epic.get("tasks", []), start=1):
        child_ref = f"E{ei}:T{ti}"
        child_id = ref_to_id.get(child_ref)
        if not child_id:
            continue
        for dep in (task.get("depends_on") or []):
            blocker_ref = dep.get("ref")
            if not blocker_ref:
                continue
            blocker_id = ref_to_id.get(blocker_ref)
            if not blocker_id:
                print(f"WARN: dependency ref {blocker_ref} not found among created tasks; skipping.", file=sys.stderr)
                continue
            run([beads, "dep", "add", child_id, blocker_id])
            deps_count += 1

print(f"Dependencies added: {deps_count}")
PY
