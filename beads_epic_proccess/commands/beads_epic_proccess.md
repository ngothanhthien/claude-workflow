---
description: beads_epic_proccess
---

## Agent References

All agent definitions (direct file references):

| Agent | File | Purpose |
|-------|------|---------|
| Orchestrator | `/home/cnnt/self/claude-workflow/beads_epic_proccess/agents/orchestrator.md` | Coordinates epic, spawns workers, handles blockers |
| Worker | `/home/cnnt/self/claude-workflow/beads_epic_proccess/agents/worker.md` | Executes assigned beads within FILE_SCOPE |
| Reporter | `/home/cnnt/self/claude-workflow/beads_epic_proccess/agents/reporter.md` | Compiles EPIC_SUMMARY.md |

**Agent Mail MCP Quick Reference**:

| Tool | Required Parameters | Common Mistake |
|------|---------------------|----------------|
| `register_agent` | `project_key`, `program`, `model`, `name`, `task_description` | ❌ `agent_name` → ✅ `name` |
| `macro_start_session` | `human_key`, `program`, `model`, `task_description` | ❌ `project_key` → ✅ `human_key` |
| `send_message` | `project_key`, `sender_name`, `to`, `subject`, `body_md` | `to` must be a list |
| `file_reservation_paths` | `project_key`, `agent_name`, `paths` | `paths` must be a list |
| `release_file_reservations` | `project_key`, `agent_name`, `paths` | Release held reservations |

**CLI Commands** (for cleanup/reset):
| Command | Purpose |
|---------|---------|
| `./beads_epic_proccess/scripts/clear_agent_mail_db.sh` | Clear Agent Mail SQLite database |

## Mermaid

```mermaid
flowchart TD
  start_node_default([Start])

  prompt_inputs[# Inputs:\n- PROJECT_ROOT\n- EPIC_ID\n- WORKER_POOL (names)\n- MAX_PARALLEL_WORKERS]

  clear_agent_mail{Branch:\nClear existing Agent Mail data?}
  subagent_clear_mail[Orchestrator:\nClear Agent Mail data\n- Remove old agents\n- Clear messages\n- Reset reservations\n- Clear checkpoint]

  preflight_mail{Branch:\nAgent Mail MCP + bv available?}
  subagent_preflight[Orchestrator:\nPreflight Check\n- call health_check()\n- verify bv installed\n- set TOOLS_AVAILABLE true/false]

  has_checkpoint{Branch:\nCheckpoint exists?\n.beads/.epic_checkpoint.json}
  subagent_load_checkpoint[Orchestrator:\nLoad checkpoint\n- Restore state\n- Resume monitoring loop]

  subagent_orchestrator[Orchestrator_Agent]

  triage_ready{Branch:\nAny READY beads under EPIC?}
  subagent_spawn_workers[Orchestrator:\nBuild tracks + Spawn Workers]
  subagent_monitor[Orchestrator:\nMonitor Mail + Beads state\n+ Save checkpoint each loop]

  has_blocker{Branch:\nAny BLOCKER mail?}
  subagent_handle_blocker[Orchestrator:\nCreate blocker/bug bead\n+ wire deps\n+ reassign work]

  epic_done{Branch:\nEpic subtree all CLOSED?}
  subagent_reporter[Agent_Reporter:\nCompile EPIC_SUMMARY.md]
  subagent_cleanup[Orchestrator:\nCleanup checkpoint\n- Remove .beads/.epic_checkpoint.json\n- Mark epic complete]

  notify_user[STOP:\nAgent Mail MCP + bv Required\n\nThis workflow REQUIRES:\n\n1. Agent Mail MCP for:\n   - thread coordination\n   - worker communication\n   - reservation system\n   - blocker handling\n\n2. bv (Beads Viewer) for:\n   - AI priority ranking (--robot-priority)\n   - parallel track planning (--robot-plan)\n   - change detection (--robot-diff)\n\nAction Required:\n1. Install Agent Mail MCP: https://github.com/dicklesworthstone/mcp_agent_mail\n2. Install bv: https://github.com/dicklesworthstone/bv\n3. Configure in Claude MCP settings\n4. Restart and retry]
  end_node_default([End])

  start_node_default --> prompt_inputs --> clear_agent_mail
  clear_agent_mail -->|Yes| subagent_clear_mail --> preflight_mail
  clear_agent_mail -->|No| preflight_mail
  preflight_mail -->|Yes| has_checkpoint
  preflight_mail -->|No| notify_user

  has_checkpoint -->|Yes| subagent_load_checkpoint --> subagent_monitor
  has_checkpoint -->|No| subagent_orchestrator
  subagent_orchestrator --> triage_ready
  triage_ready -->|Yes| subagent_spawn_workers
  triage_ready -->|No| subagent_monitor
  subagent_spawn_workers --> subagent_monitor
  subagent_monitor --> has_blocker
  has_blocker -->|Yes| subagent_handle_blocker
  has_blocker -->|No| epic_done
  subagent_handle_blocker --> subagent_monitor
  epic_done -->|No| subagent_monitor
  epic_done -->|Yes| subagent_reporter --> subagent_cleanup --> end_node_default
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
- EPIC_ID: existing Beads epic id (or leave empty to create new epic)
- WORKER_POOL: e.g. ["BlueLake","GreenCastle","RedStone"]
- MAX_PARALLEL_WORKERS: default 3

### clear_agent_mail
**Ask user**: "Do you want to clear existing Agent Mail data before starting?
- This will remove old agents, messages, and file reservations
- Useful for starting fresh after previous runs
- Choose 'No' to preserve existing coordination history"

Condition is TRUE if user confirms "Yes" or "Clear" or "Reset".

### subagent_clear_mail
When user wants to clear Agent Mail data:

```bash
./beads_epic_proccess/scripts/clear_agent_mail_db.sh
```

**NOTE**: This clears Agent Mail SQLite database files (agents, messages, reservations), NOT the Beads tasks (.beads/ directory).

### preflight_mail
Branch on TOOLS_AVAILABLE:
- true  -> continue to subagent_orchestrator
- false -> STOP and notify user

### subagent_orchestrator
Run the Orchestrator Agent from `/home/cnnt/self/claude-workflow/beads_epic_proccess/agents/orchestrator.md`.

**Full protocol**: See the file for complete instructions including:
- Checkpoint System (Phase A.5) - Resume from saved state
- Phase A-E: Complete orchestrator workflow
- Monitoring loop with checkpoint saving
- Blocker handling and epic completion

**Minimum startup actions**:
- Check for checkpoint → resume if exists
- macro_start_session() to register
- macro_prepare_thread(thread_id=EPIC_THREAD)
- br dep tree EPIC_ID
- br ready (filter to EPIC subtree)
- bv --robot-priority (get ranked tasks)
- Post track plan to EPIC thread
- Enter monitoring loop (save checkpoint each iteration)

### subagent_spawn_workers
Orchestrator spawns N workers in parallel (<= MAX_PARALLEL_WORKERS).

**CRITICAL: Agent Mail identities ≠ Running agents**

The workflow has THREE layers:
1. **Agent Mail Identity** (`register_agent`) - Creates a name in the coordination system
2. **Agent Mail Message** (`send_message`) - Puts a message in the inbox
3. **Actual Running Agent** (`Task` tool) - The process that reads and executes

**All three are required for workers to function.**

### Correct Spawn Sequence:
1. **Register identities** - `register_agent()` creates Agent Mail coordination identities
2. **Send assignments** - `send_message()` puts track details in each worker's inbox
3. **Spawn actual processes** - `Task()` tool launches real sub-agents

### subagent_worker
Run the Worker Agent from `/home/cnnt/self/claude-workflow/beads_epic_proccess/agents/worker.md`.

**Full protocol**: See the file for complete instructions including:
- MCP Agent Mail Coordination Playbook
- Phase A-E: Complete worker workflow
- Message templates ([INTENT], [UPDATE], [BLOCKED], [DONE])
- Error recovery and quality checklist

**Execution summary**:
- Phase A: macro_start_session() to register
- Phase B: Announce track start in TRACK_THREAD
- Phase C: Work beads in order (reserve → announce → work → test → sync → close → release)
- Phase D: Handle blockers (send [BLOCKED], notify EPIC_THREAD, wait for ACK)
- Phase E: Track completion (report to TRACK_THREAD, ask for more work)

### subagent_monitor
Orchestrator enters **continuous monitoring loop** (does NOT exit until epic complete):
- fetch_inbox(urgent_only=true)
- search_messages(query=EPIC_ID)
- br ready / br blocked
- bv --robot-diff --diff-since "5 minutes ago" (shows new, closed, changed tasks)
- Produce status updates every 30-60 seconds
- Loop repeats until all beads in EPIC subtree are CLOSED

If ready beads appear: assign them to an existing track or spawn a worker.

**CRITICAL**: This is a LOOP, not a one-time check. Exit condition is epic completion ONLY.

### subagent_handle_blocker
If a worker reports BLOCKER:
- Create new bead (bug/task)
- Wire dependency so original is blocked until resolved:
  - br dep add <original> <new>
- Reassign the new bead to a suitable worker/track
- Notify in EPIC thread with explicit next steps

### subagent_reporter
Run the Reporter Agent from `/home/cnnt/self/claude-workflow/beads_epic_proccess/agents/reporter.md`.

**Full protocol**: See the file for complete instructions.

**Output**:
- `reports/EPIC_ID/EPIC_SUMMARY.md`

### subagent_preflight
Orchestrator runs:
- health_check() for Agent Mail MCP
- verify bv installed: `bv --robot-help` or `which bv`
- If both succeed: TOOLS_AVAILABLE=true
- If either fails: TOOLS_AVAILABLE=false

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

### has_checkpoint
Condition is TRUE if:
- File `.beads/.epic_checkpoint.json` exists and contains valid JSON with `epic_id` field matching EPIC_ID

### subagent_load_checkpoint
When checkpoint exists, orchestrator:
1. Read `.beads/.epic_checkpoint.json`
2. Verify `epic_id` matches current EPIC_ID
3. Restore state:
   - EPIC_THREAD, TRACK_THREAD assignments
   - Active worker names and their tracks
   - Last check timestamp
4. Announce in EPIC_THREAD: "[EPIC] Resumed from checkpoint"
5. Jump directly to subagent_monitor loop

### subagent_cleanup
After epic completion and reporter:
1. Remove checkpoint: `rm .beads/.epic_checkpoint.json`
2. Final EPIC_THREAD mail: "[EPIC] COMPLETE — checkpoint cleaned up"

### epic_done
Condition is TRUE if:
- all beads in EPIC subtree are CLOSED (based on `br dep tree EPIC_ID` + status check)
