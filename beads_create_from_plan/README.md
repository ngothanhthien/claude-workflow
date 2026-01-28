# Beads: Create Issues from Plan (Claude Code)

## Contents
- `.claude/commands/beads_create_from_plan.md` — workflow command (Mermaid + script + agent calls)
- `.claude/agents/beads_plan_parser.md` — agent that produces `beads-plan.json`
- `scripts/beads/*.sh` — bash scripts used by the workflow

## Expected flow
1) `scripts/beads/detect_cli.sh` writes `.tmp/beads.env` with BEADS=br or bd
2) `scripts/beads/ensure_ws.sh` ensures `.beads` workspace exists
3) `scripts/beads/extract_plan.sh` tries to create `.tmp/plan_excerpt.md`
4) Agent `beads_plan_parser` outputs `beads-plan.json`
5) `scripts/beads/create_issues_from_json.sh` creates epics/tasks; writes `.tmp/beads-created.json`
6) `scripts/beads/add_deps_from_json.sh` adds dependencies
7) `scripts/beads/lint_and_summary.sh` prints summary

## Notes
- If your plan isn't in `tech_spec.md` or a plan file, paste it when the agent asks.
- Scripts avoid external deps (use Python stdlib).
