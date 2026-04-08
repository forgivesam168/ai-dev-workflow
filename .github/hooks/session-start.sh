#!/bin/bash
# session-start.sh - Copilot CLI sessionStart hook
# Logs session start for audit trail
# fail-open: errors exit 0 to not block development

set -euo pipefail

LOG_DIR=".copilot/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/audit.log"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
USER=$(git config user.name 2>/dev/null || echo "unknown")
EMAIL=$(git config user.email 2>/dev/null || echo "unknown")
DIR=$(pwd)

echo "[$TIMESTAMP] SESSION_START user=$USER email=$EMAIL dir=$DIR" >> "$LOG_FILE"

echo '{"decision":"allow"}'
exit 0
