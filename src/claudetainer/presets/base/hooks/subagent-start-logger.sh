#!/bin/bash

# Subagent Start Logger Hook
# Logs when a Task tool (sub-agent) is about to be invoked
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
    TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // "unknown"')
    TOOL_INPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_input // {}')
    DESCRIPTION=$(echo "$TOOL_INPUT" | jq -r '.description // "No description provided"')
    PROMPT=$(echo "$TOOL_INPUT" | jq -r '.prompt // ""' | head -c 100)
    SUBAGENT_TYPE=$(echo "$TOOL_INPUT" | jq -r '.subagent_type // ""')
else
    SESSION_ID="unknown"
    TOOL_NAME="Task"
    DESCRIPTION="Sub-agent delegation starting"
    PROMPT=""
    SUBAGENT_TYPE=""
fi

# Generate timestamp in ISO-8601 format
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Generate unique task ID
TASK_ID="task-$(date +%s)-$$"

# Create structured JSON log entry (single line for JSONL format)
if command -v jq > /dev/null 2>&1; then
    LOG_ENTRY=$(jq -c -n --arg timestamp "$TIMESTAMP" \
        --arg level "INFO" \
        --arg agent "SUBAGENT-ORCHESTRATOR" \
        --arg event "subagent_delegation_start" \
        --arg message "Delegating task to sub-agent: $DESCRIPTION" \
        --arg session_id "$SESSION_ID" \
        --arg task_id "$TASK_ID" \
        --arg tool_name "$TOOL_NAME" \
        --arg subagent_type "$SUBAGENT_TYPE" \
        --arg task_description "$DESCRIPTION" \
        --arg prompt_preview "$PROMPT" \
        --arg delegation_timestamp "$TIMESTAMP" \
        --arg memory_usage_mb "$MEMORY_USAGE_MB" \
        '{timestamp: $timestamp, level: $level, agent: $agent, event: $event, message: $message, attributes: {session_id: $session_id, task_id: $task_id, tool_name: $tool_name, subagent_type: $subagent_type, delegation_type: "task_tool_invocation", task_description: $task_description, prompt_preview: $prompt_preview, delegation_timestamp: $delegation_timestamp, memory_usage_mb: $memory_usage_mb}}')
else
    # Fallback without jq - create simple single-line JSON
    LOG_ENTRY="{\"timestamp\":\"$TIMESTAMP\",\"level\":\"INFO\",\"agent\":\"SUBAGENT-ORCHESTRATOR\",\"event\":\"subagent_delegation_start\",\"message\":\"Delegating task to sub-agent: $DESCRIPTION\",\"attributes\":{\"session_id\":\"$SESSION_ID\",\"task_id\":\"$TASK_ID\",\"tool_name\":\"$TOOL_NAME\",\"subagent_type\":\"$SUBAGENT_TYPE\",\"delegation_type\":\"task_tool_invocation\",\"task_description\":\"$DESCRIPTION\",\"prompt_preview\":\"$PROMPT\",\"delegation_timestamp\":\"$TIMESTAMP\"}}"
fi

# Write to structured log file (JSONL format)
echo "$LOG_ENTRY" >> ~/.config/claudetainer/logs/subagent.jsonl

# Store task ID for correlation with SubagentStop
echo "$TASK_ID" > "/tmp/claude-task-$SESSION_ID-current"

# Optional: Write to console for immediate visibility (comment out for production)
# echo "🚀 SUB-AGENT DELEGATION: $DESCRIPTION" >&2

# Return success (allows tool execution to continue)
exit 0
