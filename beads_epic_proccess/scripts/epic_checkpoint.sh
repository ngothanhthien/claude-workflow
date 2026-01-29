#!/usr/bin/env bash
# Epic Checkpoint Helper for Beads Orchestrator
# Usage: source scripts/epic_checkpoint.sh
#
# Functions:
#   checkpoint_exists      - Check if checkpoint file exists
#   checkpoint_load        - Load and validate checkpoint
#   checkpoint_save        - Save current state to checkpoint
#   checkpoint_clear       - Remove checkpoint file
#   checkpoint_validate    - Validate checkpoint format and epic_id match

set -euo pipefail

# Default checkpoint location (relative to PROJECT_ROOT)
CHECKPOINT_FILE="${PROJECT_ROOT}/.beads/.epic_checkpoint.json"

# checkpoint_exists: Check if checkpoint file exists
# Returns: 0 if exists, 1 if not
checkpoint_exists() {
    [[ -f "$CHECKPOINT_FILE" ]]
}

# checkpoint_validate: Validate checkpoint format and epic_id match
# Args:
#   $1 - EPIC_ID to validate against
# Returns: 0 if valid, 1 if invalid
checkpoint_validate() {
    local expected_epic_id="$1"

    if ! checkpoint_exists; then
        echo "ERROR: Checkpoint file does not exist: $CHECKPOINT_FILE" >&2
        return 1
    fi

    # Check if valid JSON
    if ! jq empty "$CHECKPOINT_FILE" 2>/dev/null; then
        echo "ERROR: Checkpoint file is not valid JSON" >&2
        return 1
    fi

    # Check epic_id matches
    local checkpoint_epic_id
    checkpoint_epic_id=$(jq -r '.epic_id' "$CHECKPOINT_FILE")

    if [[ "$checkpoint_epic_id" != "$expected_epic_id" ]]; then
        echo "ERROR: Checkpoint epic_id ($checkpoint_epic_id) does not match expected ($expected_epic_id)" >&2
        return 1
    fi

    # Check version
    local version
    version=$(jq -r '.checkpoint_version // 0' "$CHECKPOINT_FILE")
    if [[ "$version" != "1" ]]; then
        echo "ERROR: Unsupported checkpoint version: $version" >&2
        return 1
    fi

    return 0
}

# checkpoint_load: Load checkpoint and export state variables
# Args:
#   $1 - EPIC_ID to validate against
# Side effects: Exports variables: EPIC_ID, PROJECT_ROOT, ORCHESTRATOR_NAME, etc.
# Returns: 0 if loaded successfully, 1 if failed
checkpoint_load() {
    local expected_epic_id="$1"

    if ! checkpoint_validate "$expected_epic_id"; then
        return 1
    fi

    # Export variables from checkpoint
    export EPIC_ID=$(jq -r '.epic_id' "$CHECKPOINT_FILE")
    export PROJECT_ROOT=$(jq -r '.project_root' "$CHECKPOINT_FILE")
    export ORCHESTRATOR_NAME=$(jq -r '.orchestrator_name' "$CHECKPOINT_FILE")
    export EPIC_THREAD=$(jq -r '.epic_thread' "$CHECKPOINT_FILE")
    export MAX_PARALLEL_WORKERS=$(jq -r '.max_parallel_workers' "$CHECKPOINT_FILE")

    # Export worker_pool as array
    mapfile -t WORKER_POOL < <(jq -r '.worker_pool[]' "$CHECKPOINT_FILE")
    export WORKER_POOL

    echo "Loaded checkpoint from $CHECKPOINT_FILE"
    echo "  EPIC_ID: $EPIC_ID"
    echo "  Orchestrator: $ORCHESTRATOR_NAME"
    echo "  Last check: $(jq -r '.last_check' "$CHECKPOINT_FILE")"
    echo "  Tracks: $(jq '.tracks | length' "$CHECKPOINT_FILE")"

    return 0
}

# checkpoint_save: Save current state to checkpoint file
# Args:
#   $1 - EPIC_ID
#   $2 - PROJECT_ROOT
#   $3 - ORCHESTRATOR_NAME
#   $4 - EPIC_THREAD
#   $5 - TRACKS_JSON (JSON array of track objects)
#   $6 - WORKER_POOL_JSON (JSON array of worker names)
#   $7 - MAX_PARALLEL_WORKERS
checkpoint_save() {
    local epic_id="$1"
    local project_root="$2"
    local orchestrator_name="$3"
    local epic_thread="$4"
    local tracks_json="$5"
    local worker_pool_json="$6"
    local max_parallel_workers="$7"

    # Ensure .beads directory exists
    mkdir -p "$(dirname "$CHECKPOINT_FILE")"

    # Create checkpoint JSON
    jq -n \
        --arg epic_id "$epic_id" \
        --arg project_root "$project_root" \
        --arg orchestrator_name "$orchestrator_name" \
        --arg epic_thread "$epic_thread" \
        --argjson tracks "$tracks_json" \
        --argjson worker_pool "$worker_pool_json" \
        --argjson max_parallel_workers "$max_parallel_workers" \
        --arg last_check "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{
            epic_id: $epic_id,
            project_root: $project_root,
            orchestrator_name: $orchestrator_name,
            epic_thread: $epic_thread,
            tracks: $tracks,
            worker_pool: $worker_pool,
            max_parallel_workers: $max_parallel_workers,
            last_check: $last_check,
            checkpoint_version: 1
        }' > "$CHECKPOINT_FILE"

    echo "Checkpoint saved to $CHECKPOINT_FILE"
}

# checkpoint_clear: Remove checkpoint file
checkpoint_clear() {
    if checkpoint_exists; then
        rm "$CHECKPOINT_FILE"
        echo "Checkpoint removed: $CHECKPOINT_FILE"
    else
        echo "No checkpoint file to remove"
    fi
}

# checkpoint_get_tracks: Get tracks from checkpoint as JSON array
checkpoint_get_tracks() {
    if ! checkpoint_exists; then
        echo "[]" >&2
        return 1
    fi
    jq -c '.tracks' "$CHECKPOINT_FILE"
}

# checkpoint_get_last_check: Get last check timestamp from checkpoint
checkpoint_get_last_check() {
    if ! checkpoint_exists; then
        echo "" >&2
        return 1
    fi
    jq -r '.last_check' "$CHECKPOINT_FILE"
}

# Display checkpoint info for debugging
checkpoint_info() {
    if ! checkpoint_exists; then
        echo "No checkpoint found at $CHECKPOINT_FILE"
        return 1
    fi

    echo "=== Checkpoint Info ==="
    echo "File: $CHECKPOINT_FILE"
    jq '.' "$CHECKPOINT_FILE"
}
