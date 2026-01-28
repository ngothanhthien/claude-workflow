#!/usr/bin/env bash
set -euo pipefail

mkdir -p .tmp
# shellcheck disable=SC1091
source .tmp/beads.env

PLAN_JSON="beads-plan.json"
OUT_JSON=".tmp/beads-created.json"

if [ ! -f "$PLAN_JSON" ]; then
  echo "ERROR: $PLAN_JSON not found. Run the beads_plan_parser agent first." >&2
  exit 1
fi

python - <<'PY'
import json, subprocess, shlex, pathlib, sys

beads = open(".tmp/beads.env","r",encoding="utf-8").read().strip().split("=",1)[1]
plan = json.loads(pathlib.Path("beads-plan.json").read_text(encoding="utf-8"))

created = {"epics": [], "tasks": []}

def run(cmd):
    print("+", " ".join(shlex.quote(c) for c in cmd))
    res = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return res.stdout.strip()

def normalize_priority(p):
    if not p: return "2"
    p = str(p).upper().strip()
    if p.startswith("P"):
        return p[1:]
    if p in ("HIGH","H"): return "1"
    if p in ("LOW","L"): return "3"
    return "2"

labels_default = plan.get("meta", {}).get("labels_default", ["backend","api"])

for ei, epic in enumerate(plan.get("epics", []), start=1):
    title = epic["title"]
    pr = normalize_priority(epic.get("priority", "P2"))
    labels = epic.get("labels") or labels_default
    desc = (epic.get("description") or "").strip()

    cmd = [beads, "create", title, "-t", "epic", "-p", pr, "-l", ",".join(labels)]
    if desc:
        cmd += ["--description", desc]
    cmd += ["--json"]

    out = run(cmd)
    data = json.loads(out)
    epic_id = data.get("id") or (data.get("issue") or {}).get("id")
    if not epic_id:
        raise SystemExit(f"Could not parse epic id from: {out}")

    created["epics"].append({"key": epic.get("key", f"E{ei}"), "title": title, "id": epic_id})

    for ti, task in enumerate(epic.get("tasks", []), start=1):
        t_title = task["title"]
        t_pr = normalize_priority(task.get("priority", epic.get("priority","P2")))
        t_labels = task.get("labels") or labels
        t_type = task.get("type","task")
        t_desc = (task.get("description") or "").strip()

        tcmd = [beads, "create", t_title, "-t", t_type, "-p", t_pr, "-l", ",".join(t_labels), "--parent", epic_id]
        if t_desc:
            tcmd += ["--description", t_desc]
        tcmd += ["--json"]

        tout = run(tcmd)
        tdata = json.loads(tout)
        task_id = tdata.get("id") or (tdata.get("issue") or {}).get("id")
        if not task_id:
            raise SystemExit(f"Could not parse task id from: {tout}")

        created["tasks"].append({
            "ref": f"E{ei}:T{ti}",
            "epic_key": epic.get("key", f"E{ei}"),
            "epic_id": epic_id,
            "title": t_title,
            "id": task_id
        })

pathlib.Path(".tmp/beads-created.json").write_text(json.dumps(created, indent=2), encoding="utf-8")
print(f"Wrote .tmp/beads-created.json with {len(created['epics'])} epics and {len(created['tasks'])} tasks.")
PY
