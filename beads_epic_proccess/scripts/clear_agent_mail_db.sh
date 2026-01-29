#!/bin/bash
# Clear Agent Mail Database
# Removes SQLite database files for MCP Agent Mail

STORAGE_DIR="/home/cnnt/.claude/mcp_agent_mail"
FILES=(
    "storage.sqlite3"
    "storage.sqlite3-shm"
    "storage.sqlite3-wal"
)

echo "Clearing Agent Mail database..."
echo "Storage directory: $STORAGE_DIR"
echo

# Check if directory exists
if [ ! -d "$STORAGE_DIR" ]; then
    echo "Error: Directory does not exist: $STORAGE_DIR"
    exit 1
fi

# Remove files
for file in "${FILES[@]}"; do
    filepath="$STORAGE_DIR/$file"
    if [ -f "$filepath" ]; then
        rm -f "$filepath"
        echo "Removed: $file"
    else
        echo "Not found: $file"
    fi
done

echo
echo "Agent Mail database cleared."
