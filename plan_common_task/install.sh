#!/bin/bash

# Common Task Planner Installer
# Creates symbolic links from .claude/ to source folders (agents/ and commands/)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$PROJECT_ROOT/.claude"

echo "Installing Common Task Planner..."
echo "  Project root: $PROJECT_ROOT"
echo "  .claude dir:  $CLAUDE_DIR"

# Create symlinks
ln -sf "$SCRIPT_DIR/agents" "$CLAUDE_DIR/agents"
ln -sf "$SCRIPT_DIR/commands" "$CLAUDE_DIR/commands"

echo "✅ Created symlinks:"
echo "   $CLAUDE_DIR/agents → $SCRIPT_DIR/agents"
echo "   $CLAUDE_DIR/commands → $SCRIPT_DIR/commands"
