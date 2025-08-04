#!/bin/bash

# Subagent Stop Logger Hook
# Logs when a Task tool (sub-agent) completes execution
# Follows OpenTelemetry JSON structured logging format

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract relevant data using jq (gracefully handle if jq not available)
if command -v jq > /dev/null 2>&1; then
    SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.sessionId // "unknown"')
    STOP_REASON=$(echo "$HOOK_INPUT" | jq -r '.stopReason // "completed"')
    MESSAGE_COUNT=$(echo "$HOOK_INPUT" | jq -r '.messages | length // 0')
    LAST_MESSAGE=$(echo "$HOOK_INPUT" | jq -r '.messages[-1].content // ""' | head -c 200)
else
    SESSION_ID="unknown"
    STOP_REASON="completed"
    MESSAGE_COUNT=0
    LAST_MESSAGE=""
fi

# Generate timestamp in ISO-8601 format
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ" 2> /dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

# Retrieve task ID from delegation start (if available)
TASK_ID_FILE="/tmp/claude-task-$SESSION_ID-current"
if [ -f "$TASK_ID_FILE" ]; then
    TASK_ID=$(cat "$TASK_ID_FILE")
    rm -f "$TASK_ID_FILE" # Clean up
else
    TASK_ID="task-$(date +%s)-$$"
fi

# Determine completion status
if [[ "$STOP_REASON" == "completed" || "$STOP_REASON" == "max_turns" ]]; then
    STATUS="SUCCESS"
    LEVEL="INFO"
elif [[ "$STOP_REASON" == "error" || "$STOP_REASON" == "interrupted" ]]; then
    STATUS="FAILED"
    LEVEL="ERROR"
else
    STATUS="UNKNOWN"
    LEVEL="WARN"
fi

# Create log directory if it doesn't exist
mkdir -p ~/.claude/logs

# Create structured JSON log entry
LOG_ENTRY=$(
    cat << EOF
{
  "timestamp": "$TIMESTAMP",
  "level": "$LEVEL",
  "agent": "SUBAGENT-ORCHESTRATOR", 
  "event": "subagent_delegation_complete",
  "message": "Sub-agent task completed with status: $STATUS",
  "attributes": {
    "session_id": "$SESSION_ID",
    "task_id": "$TASK_ID",
    "completion_timestamp": "$TIMESTAMP",
    "status": "$STATUS",
    "stop_reason": "$STOP_REASON",
    "message_count": $MESSAGE_COUNT,
    "last_message_preview": "$LAST_MESSAGE",
    "delegation_result": {
      "success": $([ "$STATUS" = "SUCCESS" ] && echo "true" || echo "false"),
      "completion_type": "$STOP_REASON"
    }
  }
}
EOF
)

# Write to structured log file (JSONL format)
echo "$LOG_ENTRY" >> ~/.claude/logs/subagent.jsonl

# Optional: Write completion summary to console (comment out for production)
# echo "✅ SUB-AGENT COMPLETE: $STATUS ($STOP_REASON)" >&2

# Rotate log file if it gets too large (keep last 1000 entries)
LOG_FILE=~/.claude/logs/subagent.jsonl
if [ -f "$LOG_FILE" ] && [ $(wc -l < "$LOG_FILE") -gt 1000 ]; then
    tail -1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

# Return success (allows normal completion flow)
exit 0
