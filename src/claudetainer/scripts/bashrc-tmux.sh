#!/usr/bin/env bash

# bashrc-tmux.sh - Auto-start claudetainer tmux session for remote connections
# This gets appended to ~/.bashrc in the container

# Only run for interactive, remote SSH sessions
if [[ $- == *i* ]] && [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" ]] && [[ -z "$TMUX" ]]; then
    # Check if claudetainer session exists
    if tmux has-session -t claudetainer 2>/dev/null; then
        echo "🔗 Attaching to existing claudetainer session..."
        exec tmux attach-session -t claudetainer
    else
        echo "🚀 Starting new claudetainer session..."
        # Create session with claude window in /workspaces
        tmux new-session -d -s claudetainer -c /workspaces -n claude
        
        # Create usage window and run ccusage
        tmux new-window -t claudetainer:2 -n usage -c /workspaces 'npx ccusage'
        
        # Switch back to claude window and add welcome messages
        tmux select-window -t claudetainer:1
        tmux send-keys -t claudetainer:claude 'clear' Enter
        tmux send-keys -t claudetainer:claude 'echo "🤖 Welcome to claudetainer! Switch windows: Ctrl+b then 1 (claude) or 2 (usage)"' Enter
        tmux send-keys -t claudetainer:claude 'echo "💡 Start coding with: claude"' Enter
        
        # Attach to the session
        exec tmux attach-session -t claudetainer
    fi
fi