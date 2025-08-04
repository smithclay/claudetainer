#!/bin/bash

# Subagent Start Logger Hook
# Logs when a Task tool (sub-agent) is about to be invoked
# Follows OpenTelemetry JSON structured logging format

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract relevant data using jq (gracefully handle if jq not available)
if command -v jq > /dev/null 2>&1; then
    SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.sessionId // "unknown"')
    TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.toolName // "unknown"')
    TOOL_INPUT=$(echo "$HOOK_INPUT" | jq -r '.toolInput // {}')
    DESCRIPTION=$(echo "$TOOL_INPUT" | jq -r '.description // "No description provided"')
    PROMPT=$(echo "$TOOL_INPUT" | jq -r '.prompt // ""' | head -c 100)
else
    SESSION_ID="unknown"
    TOOL_NAME="Task"
    DESCRIPTION="Sub-agent delegation starting"
    PROMPT=""
fi

# Generate timestamp in ISO-8601 format
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ" 2> /dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

# Generate unique task ID
TASK_ID="task-$(date +%s)-$$"

# Create log directory if it doesn't exist
mkdir -p ~/.claude/logs

# Create structured JSON log entry
LOG_ENTRY=$(
    cat << EOF
{
  "timestamp": "$TIMESTAMP",
  "level": "INFO",
  "agent": "SUBAGENT-ORCHESTRATOR",
  "event": "subagent_delegation_start",
  "message": "Delegating task to sub-agent: $DESCRIPTION",
  "attributes": {
    "session_id": "$SESSION_ID",
    "task_id": "$TASK_ID",
    "tool_name": "$TOOL_NAME",
    "delegation_type": "task_tool_invocation",
    "task_description": "$DESCRIPTION",
    "prompt_preview": "$PROMPT",
    "delegation_timestamp": "$TIMESTAMP"
  }
}
EOF
)

# Write to structured log file (JSONL format)
echo "$LOG_ENTRY" >> ~/.claude/logs/subagent.jsonl

# Store task ID for correlation with SubagentStop
echo "$TASK_ID" > "/tmp/claude-task-$SESSION_ID-current"

# Optional: Write to console for immediate visibility (comment out for production)
# echo "🚀 SUB-AGENT DELEGATION: $DESCRIPTION" >&2

# Return success (allows tool execution to continue)
exit 0
