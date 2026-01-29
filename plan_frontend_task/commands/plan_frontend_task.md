---
description: pft_plan_frontend_task
---
```mermaid
flowchart TD
    start_node_default([Start])

    prompt_requirements[# PromptUserQuestionnaire:<br/>Collect frontend requirements<br/>→ write task-requirements.md]

    branch_packages{Branch/Switch:<br/>Has 3rd-party packages?}

    subagent_librarian[SubAgent: pft_librarian<br/>→ write librarian-notes.md]

    subagent_code_researcher[SubAgent: pft_code_researcher<br/>→ write codebase-notes.md]

    join_research((Join))

    subagent_tech_spec[SubAgent: pft_tech_spec_writer<br/>→ write tech_spec.md]

    subagent_tech_lead[SubAgent: pft_tech_lead_planner<br/>→ produce Implementation Plan markdown]

    subagent_final_merge[SubAgent: pft_final_spec_merger<br/>→ append plan into tech_spec.md]

    end_node_default([End])

    start_node_default --> prompt_requirements
    prompt_requirements --> branch_packages

    %% Run code research in parallel once requirements exist
    prompt_requirements --> subagent_code_researcher --> join_research

    branch_packages -->|Yes| subagent_librarian --> join_research
    branch_packages -->|No| join_research

    join_research --> subagent_tech_spec --> subagent_tech_lead --> subagent_final_merge --> end_node_default
```

## Workflow Execution Guide

Follow the Mermaid flowchart above. This workflow is optimized for **frontend** work only.
- **UI/UX components and screens**
- **State management and user flows**
- **API integration via repositories (with placeholder TODOs)**
- **No backend implementation**
- **No test-writing tasks**

### Execution Methods by Node Type
- **Rectangle nodes (SubAgent: ...)**: Run the specified sub-agent prompt file from `.claude/agents/`.
- **Prompt nodes**: Execute the prompt text below and write the required output file.
- **Diamond nodes (Branch/Switch: ...)**: Branch automatically based on available inputs (see rules below).
- **Join node**: Continue only after required upstream artifacts exist.

### Branch Rule: Has 3rd-party packages?
Read `task-requirements.md`:
- If it contains one or more third-party UI libraries/services → run `pft_librarian`
- Otherwise skip Librarian and continue

## Prompt Node Details

### prompt_requirements(# PromptUserQuestionnaire...)
Ask the user:
- What feature/UI do you want to build/change?
- New or modification?
- Third-party UI libraries/services? (e.g., component libraries, UI kits)
- Codebase keywords / related modules? (components, screens, features)
- API endpoints needed? (for repository layer)

Then write `task-requirements.md` using the `pft_requirements_intake` agent output format.

### join_research((Join))
Ensure these files exist before proceeding:
- `task-requirements.md`
- `codebase-notes.md`
- (optional) `librarian-notes.md`

## Expected Artifacts (files)
- `task-requirements.md`
- `codebase-notes.md`
- `librarian-notes.md` (optional)
- `tech_spec.md` (final)
