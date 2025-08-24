#!/bin/bash

# Subagent Log Viewer
# View and analyze structured JSON logs from sub-agent delegation hooks

LOG_FILE=~/.config/claudetainer/logs/subagent.jsonl
USAGE="Usage: $0 [tail|stats|search <pattern>|session <session_id>]"

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "No subagent logs found at $LOG_FILE"
    echo "Logs will be created when sub-agents are used with Claude Code."
    exit 0
fi

# Function to pretty print JSON log entry
pretty_print_entry() {
    local entry="$1"
    if command -v jq >/dev/null 2>&1; then
        echo "$entry" | jq -r '
            "\(.timestamp) [\(.level)] \(.agent) - \(.event)
            Message: \(.message)
            Task ID: \(.attributes.task_id // "N/A")
            Session: \(.attributes.session_id // "N/A")
            Status: \(.attributes.status // .attributes.delegation_type // "N/A")
            Memory: \(.attributes.memory_usage_mb // "N/A")MB"
        '
    else
        echo "$entry"
    fi
    echo "---"
}

# Main command handling
case "${1:-tail}" in
"tail")
    echo "📊 Latest Sub-Agent Activity (last 10 entries):"
    echo "==============================================="
    tail -10 "$LOG_FILE" | while read -r line; do
        pretty_print_entry "$line"
    done
    ;;

"stats")
    echo "📈 Sub-Agent Logging Statistics:"
    echo "================================"
    if command -v jq >/dev/null 2>&1; then
        echo "Total Entries: $(wc -l <"$LOG_FILE")"
        echo "Delegations Started: $(grep -c 'subagent_delegation_start' "$LOG_FILE")"
        echo "Delegations Completed: $(grep -c 'subagent_delegation_complete' "$LOG_FILE")"
        echo "Success Rate: $(jq -r 'select(.attributes.status == "SUCCESS")' <"$LOG_FILE" | wc -l)/$(grep -c 'subagent_delegation_complete' "$LOG_FILE")"
        echo ""
        echo "Memory Usage Statistics:"
        echo "Average Memory: $(jq -r 'select(.attributes.memory_usage_mb != null) | .attributes.memory_usage_mb' <"$LOG_FILE" | awk '{sum+=$1; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')MB"
        echo "Peak Memory: $(jq -r 'select(.attributes.memory_usage_mb != null) | .attributes.memory_usage_mb' <"$LOG_FILE" | sort -n | tail -1)MB"
        echo ""
        echo "Recent Sessions:"
        jq -r '.attributes.session_id' <"$LOG_FILE" | tail -5 | sort -u
    else
        echo "Install 'jq' for detailed statistics"
        echo "Total log entries: $(wc -l <"$LOG_FILE")"
    fi
    ;;

"search")
    if [ -z "$2" ]; then
        echo "$USAGE"
        exit 1
    fi
    echo "🔍 Search Results for: $2"
    echo "========================"
    grep -i "$2" "$LOG_FILE" | while read -r line; do
        pretty_print_entry "$line"
    done
    ;;

"session")
    if [ -z "$2" ]; then
        echo "$USAGE"
        exit 1
    fi
    echo "📋 Session Activity: $2"
    echo "======================"
    if command -v jq >/dev/null 2>&1; then
        jq -r --arg session "$2" 'select(.attributes.session_id == $session)' <"$LOG_FILE" | while read -r line; do
            pretty_print_entry "$line"
        done
    else
        grep "$2" "$LOG_FILE" | while read -r line; do
            pretty_print_entry "$line"
        done
    fi
    ;;

"clear")
    echo "🗑️  Clearing subagent logs..."
    true >"$LOG_FILE"
    echo "Logs cleared."
    ;;

*)
    echo "$USAGE"
    echo ""
    echo "Commands:"
    echo "  tail     - Show last 10 log entries (default)"
    echo "  stats    - Show logging statistics"
    echo "  search   - Search for pattern in logs"
    echo "  session  - Show all entries for a session ID"
    echo "  clear    - Clear all logs"
    ;;
esac
