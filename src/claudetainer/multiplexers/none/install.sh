#!/usr/bin/env bash

# none/install.sh - No multiplexer configuration

set -euo pipefail

# Source base utilities
# shellcheck source=../base.sh
source "$(dirname "${BASH_SOURCE[0]}")/../base.sh"

# Check if multiplexer is available (always false for none)
is_multiplexer_available() {
    return 0 # Always "available" since we're not using one
}

# Setup simple bash environment without multiplexer
setup_simple_environment() {
    local target_home="${TARGET_HOME:-$HOME}"
    local bashrc="$target_home/.bashrc"

    log_info "Setting up simple bash environment..."

    # Create a simple welcome script
    mkdir -p "$target_home/.claude/scripts"
    cat > "$target_home/.claude/scripts/bashrc-multiplexer.sh" << 'EOF'
#!/usr/bin/env bash

# bashrc-multiplexer.sh - Simple environment setup (no multiplexer)
# This gets appended to ~/.bashrc in the container

# Only run for interactive, remote SSH sessions
if [[ $- == *i* ]] && [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" ]]; then
    # Change to workspaces directory
    if [[ -d "/workspaces" ]] && [[ "$PWD" != "/workspaces" ]]; then
        cd /workspaces || true
    fi
    
    # Display welcome message
    echo "🤖 Welcome to Claudetainer!"
    echo "💡 No multiplexer configured - using simple bash session"
    echo "🚀 Start coding with: claude"
    echo "📊 Monitor usage in another terminal with: npx ccusage"
    echo
fi
EOF

    # Append to bashrc if not already present
    if ! grep -q "bashrc-multiplexer.sh" "$bashrc" 2> /dev/null; then
        echo "" >> "$bashrc"
        echo "# Claudetainer: Simple environment setup (no multiplexer)" >> "$bashrc"
        echo "source ~/.claude/scripts/bashrc-multiplexer.sh" >> "$bashrc"
        log_success "Added simple environment setup to ~/.bashrc"
    else
        log_info "Simple environment already configured in ~/.bashrc"
    fi
}

# Setup auto-start (for consistency with interface)
setup_auto_start() {
    setup_simple_environment
}

# Main installation function
install_multiplexer() {
    setup_simple_environment

    log_success "Simple bash environment setup complete"
    log_info "No multiplexer configured - using standard bash sessions"
    log_info "Consider using 'zellij' or 'tmux' for enhanced remote development"
}
