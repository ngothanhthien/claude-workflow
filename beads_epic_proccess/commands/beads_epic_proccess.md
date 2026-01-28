---
description: beads_epic_proccess
---

## Mermaid

```mermaid
flowchart TD
  start_node_default([Start])

  prompt_inputs[# Inputs:\n- PROJECT_ROOT\n- EPIC_ID\n- WORKER_POOL (names)\n- MAX_PARALLEL_WORKERS]

  preflight_mail{Branch:\nAgent Mail MCP + bv available?}
  subagent_preflight[Orchestrator:\nPreflight Check\n- call health_check()\n- verify bv installed\n- set TOOLS_AVAILABLE true/false]

  subagent_orchestrator[Orchestrator_Agent]

  triage_ready{Branch:\nAny READY beads under EPIC?}
  subagent_spawn_workers[Orchestrator:\nBuild tracks + Spawn Workers]
  subagent_monitor[Orchestrator:\nMonitor Mail + Beads state]

  has_blocker{Branch:\nAny BLOCKER mail?}
  subagent_handle_blocker[Orchestrator:\nCreate blocker/bug bead\n+ wire deps\n+ reassign work]

  epic_done{Branch:\nEpic subtree all CLOSED?}
  subagent_reporter[Agent_Reporter:\nCompile EPIC_SUMMARY.md]

  notify_user[STOP:\nAgent Mail MCP + bv Required\n\nThis workflow REQUIRES:\n\n1. Agent Mail MCP for:\n   - thread coordination\n   - worker communication\n   - reservation system\n   - blocker handling\n\n2. bv (Beads Viewer) for:\n   - AI priority ranking (--robot-priority)\n   - parallel track planning (--robot-plan)\n   - change detection (--robot-diff)\n\nAction Required:\n1. Install Agent Mail MCP: https://github.com/dicklesworthstone/mcp_agent_mail\n2. Install bv: https://github.com/dicklesworthstone/bv\n3. Configure in Claude MCP settings\n4. Restart and retry]
  end_node_default([End])

  start_node_default --> prompt_inputs --> subagent_preflight --> preflight_mail
  preflight_mail -->|Yes| subagent_orchestrator
  preflight_mail -->|No| notify_user

  subagent_orchestrator --> triage_ready
  triage_ready -->|Yes| subagent_spawn_workers
  triage_ready -->|No| subagent_monitor
  subagent_spawn_workers --> subagent_monitor
  subagent_monitor --> has_blocker
  has_blocker -->|Yes| subagent_handle_blocker
  has_blocker -->|No| epic_done
  subagent_handle_blocker --> subagent_monitor
  epic_done -->|No| subagent_monitor
  epic_done -->|Yes| subagent_reporter --> end_node_default
```

---

## Define node type

### Execution Methods by Node Type
- **Rectangle nodes (Sub-Agents)**: Run the specified agent prompt (Orchestrator / Worker / Reporter).
- **Diamond nodes (Branch: ...)**: Automatically branch based on the latest Beads + Agent Mail state.
- **Prompt nodes**: Collect required inputs and set them as variables.

---

## Key conventions (must be enforced)
- **Threads**: Each thread is a unique conversation thread in the EPIC thread.
- **EPIC_THREAD = EPIC_ID**

- TRACK_THREAD(agent) = "track:<agent>:<EPIC_ID>"

- BEAD_THREAD = BEAD_ID (e.g., "br-42")

- **Subjects**:
  - **Bead Messages**: "[<BEAD_ID>] ..."
  - **Track Summaries**: "[Track] ..."

- **Reservations**:
  - Reserve before edits. Release at bead end.
  - For shared files/scope, require COORD + ACK in EPIC thread.
---

## Guiding Claude (Workflow Execution Guide)

### prompt_inputs
Collect and set:
- PROJECT_ROOT: absolute repo path
- EPIC_ID: existing Beads epic id
- WORKER_POOL: e.g. ["BlueLake","GreenCastle","RedStone"]
- MAX_PARALLEL_WORKERS: default 3

### subagent_orchestrator
Run the Orchestrator Agent Prompt.
Minimum required actions:
- macro_start_session() (handles: ensure_project, register_agent, inbox fetch)
- macro_prepare_thread(thread_id=EPIC_THREAD)
- br dep tree EPIC_ID
- br ready (filter to EPIC subtree)
- bv --robot-priority (get ranked tasks with impact scores)
- Post track plan to EPIC thread

### subagent_spawn_workers
Orchestrator spawns N workers in parallel (<= MAX_PARALLEL_WORKERS).
Build tracks using bv --robot-plan (analyzes dependency chains, identifies parallelizable work).
Each worker receives:
- BEAD_LIST ordered (deps-safe)
- FILE_SCOPE
- EPIC_THREAD & TRACK_THREAD

Workers use agents/worker.md prompt which follows Agent Mail MCP recommended flow:
- macro_start_session() for registration
- macro_file_reservation_cycle(reason=bead_id) for per-bead reservations
- BEAD_THREAD communication for each bead
- Proper sync: br sync --flush-only + git add .beads/ + git commit

### subagent_worker
Run the Worker Agent Prompt.
Each worker executes beads in their assigned track:
- macro_start_session() to register
- For each bead: reserve, announce, work, sync, close, release
- Use BEAD_THREAD for bead-level communication
- Use TRACK_THREAD for track-level updates
- Report blockers with details for orchestrator resolution

### subagent_monitor
Orchestrator monitors:
- fetch_inbox(urgent_only=true)
- search_messages(query=EPIC_ID)
- br ready / br blocked
- bv --robot-diff --diff-since "1 hour ago" (shows new, closed, changed tasks)
If ready beads appear: assign them to an existing track or spawn a worker.

### subagent_handle_blocker
If a worker reports BLOCKER:
- Create new bead (bug/task)
- Wire dependency so original is blocked until resolved:
  - br dep add <original> <new>
- Reassign the new bead to a suitable worker/track
- Notify in EPIC thread with explicit next steps

### subagent_reporter
Run Agent Reporter Prompt to generate:
- reports/EPIC_ID/EPIC_SUMMARY.md

### subagent_preflight
Orchestrator runs:
- health_check() for Agent Mail MCP
- verify bv installed: `bv --robot-help` or `which bv`
- If both succeed: TOOLS_AVAILABLE=true
- If either fails: TOOLS_AVAILABLE=false

### preflight_mail
Branch on TOOLS_AVAILABLE:
- true  -> continue to subagent_orchestrator
- false -> STOP and notify user

### notify_user
STOP workflow when Agent Mail MCP or bv is unavailable.
Display clear error message with:
- Why Agent Mail MCP is required (thread coordination, worker communication, reservations, blocker handling)
- Why bv is required (AI priority ranking, parallel track planning, change detection)
- Installation links:
  - Agent Mail MCP: https://github.com/dicklesworthstone/mcp_agent_mail
  - bv: https://github.com/dicklesworthstone/bv
- Configuration steps
Workflow cannot proceed without both tools.

### triage_ready
Condition is TRUE if:
- `br ready` filtered to EPIC subtree returns >= 1 bead

### has_blocker
Condition is TRUE if:
- fetch_inbox(urgent_only=true) contains subject/body marker "BLOCKER"
  (or search_messages(query="[br-] BLOCKER" + EPIC_ID) when available)

### epic_done
Condition is TRUE if:
- all beads in EPIC subtree are CLOSED (based on `br dep tree EPIC_ID` + status check)
