#!/usr/bin/env bash

# bashrc-multiplexer.sh - Auto-start Zellij session for remote connections
# This gets appended to ~/.bashrc in the container

# Configure default Zellij layout - will be substituted during installation
export ZELLIJ_LAYOUT="__ZELLIJ_LAYOUT__"

# Only run for remote SSH sessions (including VS Code terminals), and not already in Zellij
# Check for SSH connection OR VS Code remote connection, and ensure we have a terminal
if [[ (-n "\${SSH_CONNECTION:-}" || -n "\${SSH_CLIENT:-}" || -n "\${VSCODE_IPC_HOOK_CLI:-}") ]] && [[ -z "\$ZELLIJ" ]] && [[ -t 0 ]]; then

    # Function to start regular shell with helpful message
    start_fallback_shell() {
        local reason="\$1"
        echo "⚠️  Zellij startup failed: \$reason"
        echo "🐚 Falling back to regular shell..."
        echo "💡 You can try manually: zellij --layout \$ZELLIJ_LAYOUT --session claudetainer"
        echo "🔧 Or use basic shell commands as normal"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📁 Working directory: \$(pwd)"
        echo "🚀 Ready for development!"
        echo ""
        # Continue with normal shell - do NOT exec to avoid terminating session
        return 0
    }

    # Check if Zellij is available
    if ! command -v zellij > /dev/null 2>&1; then
        start_fallback_shell "Zellij not installed or not in PATH"
    else
        echo "🚀 Starting/attaching to claudetainer session with Zellij..."

        # Check if claudetainer session exists, attach if it does
        if zellij list-sessions 2> /dev/null | grep -q "claudetainer"; then
            echo "🔗 Attaching to existing claudetainer session..."
            # Try to attach, fallback to shell if it fails
            if ! zellij attach claudetainer 2> /dev/null; then
                start_fallback_shell "Failed to attach to existing session"
            fi
        else
            echo "🆕 Creating new claudetainer session with configured layout..."
            echo "💡 Available layouts: tablet \\(enhanced\\), phone \\(minimal\\)"

            # Determine which layout to use based on configuration
            local layout_to_use=\"\$ZELLIJ_LAYOUT\"

            # Check if the configured layout exists
            if [ -f ~/.config/zellij/layouts/\"\$layout_to_use\".kdl ]; then
                echo "✅ Using configured layout: \$layout_to_use"
            else
                echo "⚠️  Configured layout not found, falling back to: tablet"
                layout_to_use=\"tablet\"
            fi

            # Try to start new session with error handling
            if ! zellij --new-session-with-layout \"\$layout_to_use\" -s claudetainer 2> /dev/null; then
                start_fallback_shell "Starting zellij with layout \$layout_to_use failed to start"
            fi
        fi
    fi
fi
