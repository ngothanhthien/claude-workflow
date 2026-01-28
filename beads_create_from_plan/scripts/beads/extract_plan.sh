#!/usr/bin/env bash
set -euo pipefail

mkdir -p .tmp

PLAN_OUT=".tmp/plan_excerpt.md"
: > "$PLAN_OUT"

# Priority 1: tech_spec.md section "## 9) Implementation Plan"
if [ -f "tech_spec.md" ]; then
  python - <<'PY'
import re, pathlib
p = pathlib.Path("tech_spec.md")
txt = p.read_text(encoding="utf-8", errors="ignore")
m = re.search(r"^##\s*9\)\s*Implementation Plan\s*$", txt, flags=re.M)
if not m:
    m = re.search(r"^##\s*Implementation Plan\s*$", txt, flags=re.M)
if m:
    start = m.start()
    rest = txt[start:]
    lines = rest.splitlines(True)
    cut = None
    for i in range(1, len(lines)):
        if re.match(r"^##\s+.+", lines[i]):
            cut = i
            break
    excerpt = "".join(lines if cut is None else lines[:cut])
    pathlib.Path(".tmp/plan_excerpt.md").write_text(excerpt.strip()+"\n", encoding="utf-8")
    print("Extracted plan from tech_spec.md -> .tmp/plan_excerpt.md")
else:
    print("No Implementation Plan section found in tech_spec.md")
PY
fi

# Priority 2: fallback plan files
if [ ! -s "$PLAN_OUT" ]; then
  for f in "implementation-plan.md" "PLAN.md" "plan.md"; do
    if [ -f "$f" ]; then
      cp "$f" "$PLAN_OUT"
      echo "Copied $f -> $PLAN_OUT"
      break
    fi
  done
fi

if [ ! -s "$PLAN_OUT" ]; then
  echo "WARN: Could not find a plan file/section. You may need to paste the plan text for the beads_plan_parser agent." >&2
else
  echo "Plan excerpt ready at $PLAN_OUT"
fi
