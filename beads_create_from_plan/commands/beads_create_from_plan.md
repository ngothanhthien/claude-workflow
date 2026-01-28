---
description: beads_create_from_plan
---
```mermaid
flowchart TD
    start([Start])

    script_detect_cli[/Script: scripts/beads/detect_cli.sh/]
    script_ensure_ws[/Script: scripts/beads/ensure_ws.sh/]
    script_extract_plan[/Script: scripts/beads/extract_plan.sh/]

    agent_parse_plan[SubAgent: beads_plan_parser<br/>→ writes beads-plan.json]

    script_create_issues[/Script: scripts/beads/create_issues_from_json.sh/]
    deps_branch{Branch/Switch:<br/>Any dependencies in beads-plan.json?}
    script_add_deps[/Script: scripts/beads/add_deps_from_json.sh/]
    script_lint_summary[/Script: scripts/beads/lint_and_summary.sh/]

    end([End])

    start --> script_detect_cli --> script_ensure_ws --> script_extract_plan --> agent_parse_plan --> script_create_issues --> deps_branch
    deps_branch -->|Yes| script_add_deps --> script_lint_summary --> end
    deps_branch -->|No| script_lint_summary --> end
```

## Workflow Execution Guide

This command converts an Implementation Plan into Beads Epics/Tasks + Dependencies using scripts in `scripts/beads/`.

### What this workflow produces
- `.tmp/plan_excerpt.md` (extracted plan section, if available)
- `beads-plan.json` (structured plan)
- `.tmp/beads-created.json` (IDs returned by Beads create calls)
- Beads issues in `.beads/`

### Execution Methods
- **Script nodes**: run the referenced bash scripts.
- **SubAgent node**: run the prompt in `.claude/agents/beads_plan_parser.md`.

### Branch Rule: Any dependencies?
- The script `scripts/beads/add_deps_from_json.sh` will no-op if no dependencies exist, but the diagram branches for clarity.
