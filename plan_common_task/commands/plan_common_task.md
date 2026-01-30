---
description: pct_plan_common_task
---
```mermaid
flowchart TD
    start_node_default([Start])

    prompt_input[# PromptInput:<br/>Get spec/content from user<br/>→ write input-spec.md]

    subagent_classifier[SubAgent: pct_classifier<br/>→ classify task type<br/>→ ask user to confirm]

    branch_task_type{Branch/Switch:<br/>Task type?}

    %% Bug fix flow
    subagent_bug_fix_keywords[SubAgent: pct_bug_fix_keywords<br/>→ get relevant keywords]
    subagent_bug_fix_researcher[SubAgent: pct_bug_fix_researcher<br/>→ search codebase<br/>→ identify root cause]
    prompt_bug_fix_confirm[# PromptConfirm:<br/>User confirms root cause<br/>→ write root-cause-confirmed.md]
    subagent_bug_fix_planner[SubAgent: pct_planner<br/>→ produce bug fix plan]

    %% New feature flow
    subagent_new_feature_questions[SubAgent: pct_new_feature_questions<br/>→ collect feature details]
    branch_packages{Branch/Switch:<br/>Has packages?}
    subagent_librarian[SubAgent: pct_librarian<br/>→ Context7 research<br/>→ write librarian-notes.md]
    subagent_new_feature_researcher[SubAgent: pct_new_feature_researcher<br/>→ write codebase-notes.md]
    join_new_feature((Join))
    subagent_erd_proposer[SubAgent: pct_erd_proposer<br/>→ propose ERD<br/>→ write erd-proposal.md]
    prompt_erd_confirm[# PromptConfirm:<br/>User approves ERD]
    subagent_use_case_identifier[SubAgent: pct_use_case_identifier<br/>→ identify use cases<br/>→ write use-cases.md]
    prompt_use_case_confirm[# PromptConfirm:<br/>User approves use cases]
    subagent_new_feature_planner[SubAgent: pct_planner<br/>→ produce implementation plan]

    %% Feature modification flow (A → B)
    subagent_modification_keywords[SubAgent: pct_modification_keywords<br/>→ get relevant keywords]
    subagent_modification_researcher[SubAgent: pct_modification_researcher<br/>→ identify current logic<br/>→ write current-logic.md]
    prompt_current_logic_confirm[# PromptConfirm:<br/>User approves current logic]
    subagent_modification_target[SubAgent: pct_modification_target<br/>→ describe new target logic<br/>→ write target-logic.md]
    prompt_target_logic_confirm[# PromptConfirm:<br/>User approves target logic]
    subagent_modification_planner[SubAgent: pct_planner<br/>→ produce modification plan]

    %% Feature extension flow (add C)
    subagent_extension_keywords[SubAgent: pct_extension_keywords<br/>→ get relevant keywords]
    subagent_extension_researcher[SubAgent: pct_extension_researcher<br/>→ identify current logic<br/>→ write current-logic.md]
    prompt_extension_current_confirm[# PromptConfirm:<br/>User approves current logic]
    subagent_extension_analysis[SubAgent: pct_extension_analysis<br/>→ determine new entities/functions<br/>→ write extension-analysis.md]
    prompt_extension_analysis_confirm[# PromptConfirm:<br/>User approves analysis]
    subagent_extension_planner[SubAgent: pct_planner<br/>→ produce extension plan]

    end_node_default([End])

    %% Main flow
    start_node_default --> prompt_input --> subagent_classifier --> branch_task_type

    %% Bug fix branch
    branch_task_type -->|Bug fix| subagent_bug_fix_keywords --> subagent_bug_fix_researcher --> prompt_bug_fix_confirm --> subagent_bug_fix_planner --> end_node_default

    %% New feature branch
    branch_task_type -->|New feature| subagent_new_feature_questions --> branch_packages
    branch_packages -->|Yes| subagent_librarian --> join_new_feature
    branch_packages -->|No| join_new_feature
    subagent_new_feature_questions --> subagent_new_feature_researcher --> join_new_feature
    join_new_feature --> subagent_erd_proposer --> prompt_erd_confirm --> subagent_use_case_identifier --> prompt_use_case_confirm --> subagent_new_feature_planner --> end_node_default

    %% Feature modification branch (A → B)
    branch_task_type -->|Feature modification| subagent_modification_keywords --> subagent_modification_researcher --> prompt_current_logic_confirm --> subagent_modification_target --> prompt_target_logic_confirm --> subagent_modification_planner --> end_node_default

    %% Feature extension branch
    branch_task_type -->|Feature extension| subagent_extension_keywords --> subagent_extension_researcher --> prompt_extension_current_confirm --> subagent_extension_analysis --> prompt_extension_analysis_confirm --> subagent_extension_planner --> end_node_default
```

## Workflow Execution Guide

Follow the Mermaid flowchart above. This workflow handles **all task types** with appropriate routing.

### Execution Methods by Node Type
- **Rectangle nodes (SubAgent: ...)**: Run the specified sub-agent prompt file from `.claude/agents/`.
- **Prompt nodes**: Execute the prompt text below and write the required output file.
- **Diamond nodes (Branch/Switch: ...)**: Branch based on classification result.
- **Join node**: Continue only after required upstream artifacts exist.

### Branch Rules

#### Branch: Task type?
Based on classification from `pct_classifier`:
- **Bug fix** → bug fix flow
- **Feature modification (A → B)** → modification flow
- **Feature extension (add C)** → extension flow
- **New feature** → new feature flow

#### Branch: Has packages?
Read `input-spec.md`:
- If it mentions packages/libraries → run `pct_librarian`
- Otherwise skip Librarian and continue

## Prompt Node Details

### prompt_input(# PromptInput...)
Get the spec/content from the user:
- What is the task/request?
- Paste the spec or describe the requirement

Write `input-spec.md` with the raw user input.

### prompt_bug_fix_confirm(# PromptConfirm...)
Share root cause findings from `pct_bug_fix_researcher` and ask user to confirm before proceeding to planning.

### prompt_erd_confirm(# PromptConfirm...)
Share ERD proposal from `pct_erd_proposer` and ask user to approve before identifying use cases.

### prompt_use_case_confirm(# PromptConfirm...)
Share use cases from `pct_use_case_identifier` and ask user to approve before planning.

### prompt_current_logic_confirm(# PromptConfirm...)
Share current logic description and ask user to approve before describing target logic.

### prompt_target_logic_confirm(# PromptConfirm...)
Share target logic description and ask user to approve before planning.

### prompt_extension_current_confirm(# PromptConfirm...)
Share current logic and ask user to approve before extension analysis.

### prompt_extension_analysis_confirm(# PromptConfirm...)
Share extension analysis and ask user to approve before planning.

## Expected Artifacts (files)

**Common**:
- `input-spec.md` — User's raw input

**Bug fix flow**:
- `classification-result.md` — Task type classification
- `bug-fix-keywords.md` — Relevant keywords for searching
- `root-cause-analysis.md` — Root cause findings
- `root-cause-confirmed.md` — User confirmation
- `implementation-plan.md` — Final plan

**New feature flow**:
- `classification-result.md`
- `new-feature-details.md` — Collected feature details
- `librarian-notes.md` — Package research (optional)
- `codebase-notes.md` — Codebase research
- `erd-proposal.md` — Proposed ERD
- `erd-confirmed.md` — User approval
- `use-cases.md` — Identified use cases
- `use-cases-confirmed.md` — User approval
- `implementation-plan.md` — Final plan

**Feature modification flow**:
- `classification-result.md`
- `modification-keywords.md` — Relevant keywords
- `current-logic.md` — Current logic description
- `current-logic-confirmed.md` — User approval
- `target-logic.md` — Target logic description
- `target-logic-confirmed.md` — User approval
- `implementation-plan.md` — Final plan

**Feature extension flow**:
- `classification-result.md`
- `extension-keywords.md` — Relevant keywords
- `current-logic.md` — Current logic description
- `current-logic-confirmed.md` — User approval
- `extension-analysis.md` — New entities/functions/behavior
- `extension-analysis-confirmed.md` — User approval
- `implementation-plan.md` — Final plan
