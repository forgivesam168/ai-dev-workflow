#!/bin/bash
# post-tool-use.sh - Copilot CLI postToolUse hook
# Logs tool execution results for audit
# fail-open: errors exit 0 to not block development

set -euo pipefail

INPUT=$(cat)
LOG_DIR=".copilot/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/audit.log"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name','unknown'))" 2>/dev/null || echo "unknown")
EXIT_CODE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('exit_code','?'))" 2>/dev/null || echo "?")

echo "[$TIMESTAMP] TOOL_USED tool=$TOOL exit_code=$EXIT_CODE" >> "$LOG_FILE"

echo '{"decision":"allow"}'
exit 0
