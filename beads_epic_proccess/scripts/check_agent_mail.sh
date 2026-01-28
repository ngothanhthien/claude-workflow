#!/usr/bin/env bash
set -euo pipefail

# Check whether Agent Mail MCP server is reachable.
#
# IMPORTANT: This script is a PRELIMINARY check only.
# The definitive health check MUST be done by the agent calling:
#   health_check() tool via Agent Mail MCP
#
# Agent Mail MCP provides these key tools:
#   - health_check()          : Verify server reachability
#   - ensure_project()        : Create/get project context
#   - register_agent()        : Register agent identity
#
# This script checks for common MCP environment indicators.

echo "== Checking Agent Mail MCP availability =="

# Check 1: MCP_SERVER_URL or AGENT_MAIL_URL environment variable
if [[ -n "${MCP_SERVER_URL:-}" ]] || [[ -n "${AGENT_MAIL_URL:-}" ]]; then
    echo "INFO: MCP server URL detected via environment variable."
    echo "NOTE: Actual tool availability must be verified by agent calling health_check()"
    exit 0
fi

# Check 2: Claude Code MCP configuration file
CLAUDE_CONFIG="${HOME}/.claude/mcp_config.json"
if [[ -f "$CLAUDE_CONFIG" ]]; then
    if grep -qi "agent.*mail\|mcp.*agent.*mail" "$CLAUDE_CONFIG" 2>/dev/null; then
        echo "INFO: Agent Mail MCP found in Claude config."
        echo "NOTE: Actual tool availability must be verified by agent calling health_check()"
        exit 0
    fi
fi

# Check 3: Common MCP port (default 8765 for Agent Mail)
if command -v curl >/dev/null 2>&1; then
    if curl -s --connect-timeout 2 "http://127.0.0.1:8765/health/liveness" >/dev/null 2>&1; then
        echo "INFO: Agent Mail server detected on port 8765."
        echo "NOTE: Actual tool availability must be verified by agent calling health_check()"
        exit 0
    fi
fi

# No indicators found - agent should still attempt health_check() directly
echo "WARN: No Agent Mail MCP environment indicators found."
echo "RECOMMENDED: Have the agent call health_check() tool directly to verify availability."
echo ""
echo "Example agent call:"
echo "  result = health_check()"
echo "  if result.get('status') == 'ok':"
echo "      MAIL_AVAILABLE = true"
exit 2
