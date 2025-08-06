#!/bin/bash

# Subagent Stop Logger Hook
# Logs when a Task tool (sub-agent) completes execution
# Follows OpenTelemetry JSON structured logging format

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Create log directory if it doesn't exist
mkdir -p ~/.config/claudetainer/logs

# Get memory usage for monitoring
MEMORY_USAGE_MB=""
if command -v node > /dev/null 2>&1; then
    # Get Node.js memory usage if available
    MEMORY_USAGE_MB=$(node -e "const used = process.memoryUsage(); console.log(Math.round(used.heapUsed / 1024 / 1024))" 2> /dev/null || echo "0")
fi

# Extract relevant data using jq (gracefully handle if jq not available)
if command -v jq > /dev/null 2>&1; then
    SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // "unknown"')
    STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')
    # SubagentStop provides minimal data - just session_id and stop_hook_active
    STOP_REASON="completed"
    MESSAGE_COUNT=0
    LAST_MESSAGE=""
else
    SESSION_ID="unknown"
    STOP_HOOK_ACTIVE="false"
    STOP_REASON="completed"
    MESSAGE_COUNT=0
    LAST_MESSAGE=""
fi

# Generate timestamp in ISO-8601 format
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Retrieve task ID from delegation start (if available)
TASK_ID_FILE="/tmp/claude-task-$SESSION_ID-current"
if [ -f "$TASK_ID_FILE" ]; then
    TASK_ID=$(cat "$TASK_ID_FILE")
    rm -f "$TASK_ID_FILE" # Clean up
else
    TASK_ID="task-$(date +%s)-$$"
fi

# Determine completion status based on available data
# SubagentStop hook has minimal data, so assume success unless stop_hook_active indicates otherwise
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
    STATUS="INTERRUPTED"
    LEVEL="WARN"
else
    STATUS="SUCCESS"
    LEVEL="INFO"
fi

# Create structured JSON log entry (single line for JSONL format)
SUCCESS_BOOL=$([ "$STATUS" = "SUCCESS" ] && echo "true" || echo "false")

if command -v jq > /dev/null 2>&1; then
    LOG_ENTRY=$(jq -c -n --arg timestamp "$TIMESTAMP" \
        --arg level "$LEVEL" \
        --arg agent "SUBAGENT-ORCHESTRATOR" \
        --arg event "subagent_delegation_complete" \
        --arg message "Sub-agent task completed with status: $STATUS" \
        --arg session_id "$SESSION_ID" \
        --arg task_id "$TASK_ID" \
        --arg completion_timestamp "$TIMESTAMP" \
        --arg status "$STATUS" \
        --arg stop_hook_active "$STOP_HOOK_ACTIVE" \
        --argjson success "$SUCCESS_BOOL" \
        --arg completion_type "subagent_finished" \
        --arg memory_usage_mb "$MEMORY_USAGE_MB" \
        '{timestamp: $timestamp, level: $level, agent: $agent, event: $event, message: $message, attributes: {session_id: $session_id, task_id: $task_id, completion_timestamp: $completion_timestamp, status: $status, stop_hook_active: $stop_hook_active, memory_usage_mb: $memory_usage_mb, delegation_result: {success: $success, completion_type: $completion_type}}}')
else
    # Fallback without jq - create simple single-line JSON
    LOG_ENTRY="{\"timestamp\":\"$TIMESTAMP\",\"level\":\"$LEVEL\",\"agent\":\"SUBAGENT-ORCHESTRATOR\",\"event\":\"subagent_delegation_complete\",\"message\":\"Sub-agent task completed with status: $STATUS\",\"attributes\":{\"session_id\":\"$SESSION_ID\",\"task_id\":\"$TASK_ID\",\"completion_timestamp\":\"$TIMESTAMP\",\"status\":\"$STATUS\",\"stop_hook_active\":\"$STOP_HOOK_ACTIVE\",\"delegation_result\":{\"success\":$SUCCESS_BOOL,\"completion_type\":\"subagent_finished\"}}}"
fi

# Write to structured log file (JSONL format)
echo "$LOG_ENTRY" >> ~/.config/claudetainer/logs/subagent.jsonl

# Optional: Write completion summary to console (comment out for production)
# echo "✅ SUB-AGENT COMPLETE: $STATUS ($STOP_REASON)" >&2

# Rotate log file if it gets too large (keep last 1000 entries)
LOG_FILE=~/.config/claudetainer/logs/subagent.jsonl
if [ -f "$LOG_FILE" ] && [ $(wc -l < "$LOG_FILE") -gt 1000 ]; then
    tail -1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

# Return success (allows normal completion flow)
exit 0
