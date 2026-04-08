#!/bin/bash
# pre-tool-use.sh - Copilot CLI preToolUse hook
# Blocks dangerous commands and scans for secrets
# fail-open: errors exit 0 to not block development

set -euo pipefail

# Read tool input from stdin (Copilot passes tool info as JSON)
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "")
TOOL_INPUT=$(echo "$INPUT" | grep -o '"tool_input":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "")
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

# === DANGEROUS COMMAND PATTERNS ===
DANGEROUS_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE TABLE"
  "git push --force"
  "git push -f "
  "chmod 777"
  "chmod -R 777"
  "curl.*\|.*sh"
  "wget.*\|.*bash"
  "format c:"
  "mkfs\."
  "> /dev/sda"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qi "$pattern" 2>/dev/null; then
    echo '{"decision":"block","reason":"Dangerous command pattern detected: '"$pattern"'"}'
    exit 0
  fi
done

# === SECRET SCANNING ===
SECRET_PATTERNS=(
  "[A-Za-z0-9+/]{40}"
  "sk-[a-zA-Z0-9]{20,}"
  "ghp_[A-Za-z0-9]{36}"
  "AKIA[0-9A-Z]{16}"
  "-----BEGIN.*PRIVATE KEY-----"
  "password\s*=\s*['\"][^'\"]{8,}"
  "api_key\s*=\s*['\"][^'\"]{8,}"
)

for pattern in "${SECRET_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qP "$pattern" 2>/dev/null; then
    echo '{"decision":"warn","reason":"Possible secret detected in command. Review before proceeding."}'
    exit 0
  fi
done

# Allow by default
echo '{"decision":"allow"}'
exit 0
