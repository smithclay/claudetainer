#!/usr/bin/env bash

# tmux/install.sh - Tmux multiplexer installation and configuration

set -euo pipefail

# Source base utilities
# shellcheck source=../base.sh
source "$(dirname "${BASH_SOURCE[0]}")/../base.sh"

# Tmux-specific configuration
TMUX_CONFIG_FILE="${TARGET_HOME:-$HOME}/.tmux.conf"

# Check if tmux is available
is_multiplexer_available() {
    command -v tmux >/dev/null 2>&1
}

# Install tmux (usually pre-installed in most containers)
install_tmux_binary() {
    if is_multiplexer_available; then
        log_info "tmux already available: $(tmux -V)"
        return 0
    fi
    
    log_info "tmux not found - attempting to install..."
    
    # Try different package managers with proper error handling
    local install_success=false
    
    if command -v apt-get >/dev/null 2>&1; then
        if sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y tmux >/dev/null 2>&1; then
            install_success=true
        fi
    elif command -v yum >/dev/null 2>&1; then
        if sudo yum install -y tmux >/dev/null 2>&1; then
            install_success=true
        fi
    elif command -v apk >/dev/null 2>&1; then
        if sudo apk add --no-cache tmux >/dev/null 2>&1; then
            install_success=true
        fi
    fi
    
    if [ "$install_success" = true ]; then
        log_success "tmux installed successfully"
        return 0
    else
        log_warning "Could not install tmux automatically"
        log_warning "Please install tmux manually or use a different multiplexer"
        log_warning "For devcontainer, add: \"ghcr.io/duduribeiro/devcontainer-features/tmux:1\""
        return 1
    fi
}

# Create tmux configuration
create_tmux_config() {
    log_info "Creating tmux configuration..."
    
    cat > "$TMUX_CONFIG_FILE" << 'EOF'
# Claudetainer tmux Configuration
# Optimized for remote Claude Code development

# Use Ctrl-b as prefix (default, familiar)
set -g prefix C-b
bind C-b send-prefix

# Enable mouse support
set -g mouse on

# Improve colors and terminal support
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Increase scrollback buffer size
set -g history-limit 10000

# Display messages for longer
set -g display-time 2000
set -g display-panes-time 2000

# Faster key repetition
set -s escape-time 0

# Activity monitoring
setw -g monitor-activity on
set -g visual-activity on

# Pane navigation with Alt+hjkl (no prefix needed)
bind -n M-h select-pane -L
bind -n M-j select-pane -D
bind -n M-k select-pane -U
bind -n M-l select-pane -R

# Window navigation with Alt+numbers
bind -n M-1 select-window -t 1
bind -n M-2 select-window -t 2
bind -n M-3 select-window -t 3
bind -n M-4 select-window -t 4
bind -n M-5 select-window -t 5

# Quick pane splitting
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Reload configuration
bind r source-file ~/.tmux.conf \; display "Configuration reloaded!"

# Copy mode improvements
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-pipe-and-cancel "pbcopy"

# Status bar configuration
set -g status-position bottom
set -g status-bg '#2E3440'
set -g status-fg '#D8DEE9'
set -g status-left-length 50
set -g status-right-length 50

# Window status
setw -g window-status-current-style 'fg=#2E3440 bg=#81A1C1 bold'
setw -g window-status-current-format ' #I:#W#F '
setw -g window-status-style 'fg=#D8DEE9 bg=#3B4252'
setw -g window-status-format ' #I:#W#F '

# Pane borders
set -g pane-border-style 'fg=#3B4252'
set -g pane-active-border-style 'fg=#81A1C1'

# Status bar content
set -g status-left '#[fg=#A3BE8C,bold]#{session_name} #[fg=#D8DEE9]| '
set -g status-right '#[fg=#D8DEE9]%Y-%m-%d #[fg=#88C0D0,bold]%H:%M'

# Message styling
set -g message-style 'bg=#EBCB8B fg=#2E3440 bold'
EOF
    
    log_success "Created tmux configuration at $TMUX_CONFIG_FILE"
}

# Setup auto-start for SSH sessions
setup_auto_start() {
    local target_home="${TARGET_HOME:-$HOME}"
    local bashrc="$target_home/.bashrc"
    
    log_info "Setting up tmux auto-start..."
    
    # Create the auto-start script
    mkdir -p "$target_home/.claude/scripts"
    cat > "$target_home/.claude/scripts/bashrc-multiplexer.sh" << 'EOF'
#!/usr/bin/env bash

# bashrc-multiplexer.sh - Auto-start tmux session for remote connections
# This gets appended to ~/.bashrc in the container

# Only run for interactive, remote SSH sessions, and not already in tmux
if [[ $- == *i* ]] && [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" ]] && [[ -z "$TMUX" ]]; then
    # Check if claudetainer session exists
    if tmux has-session -t claudetainer 2>/dev/null; then
        echo "🔗 Attaching to existing claudetainer session..."
        exec tmux attach-session -t claudetainer
    else
        echo "🚀 Starting new claudetainer session with tmux..."
        # Create session with claude window in /workspaces
        tmux new-session -d -s claudetainer -c /workspaces -n claude
        
        # Create usage window and run ccusage
        tmux new-window -t claudetainer:2 -n usage -c /workspaces 'echo "📊 Claude Code Usage Monitor"; echo "Starting ccusage..."; echo; exec npx ccusage'
        
        # Switch back to claude window and add welcome messages
        tmux select-window -t claudetainer:1
        tmux send-keys -t claudetainer:claude 'clear' Enter
        tmux send-keys -t claudetainer:claude 'echo "🤖 Welcome to Claudetainer with tmux!"' Enter
        tmux send-keys -t claudetainer:claude 'echo "💡 Switch windows: Alt+1 (claude) or Alt+2 (usage)"' Enter
        tmux send-keys -t claudetainer:claude 'echo "🚀 Start coding with: claude"' Enter
        
        # Attach to the session
        exec tmux attach-session -t claudetainer
    fi
fi
EOF
    
    # Append to bashrc if not already present
    if ! grep -q "bashrc-multiplexer.sh" "$bashrc" 2>/dev/null; then
        echo "" >> "$bashrc"
        echo "# Claudetainer: Auto-start multiplexer session for remote connections" >> "$bashrc"
        echo "source ~/.claude/scripts/bashrc-multiplexer.sh" >> "$bashrc"
        log_success "Added tmux auto-start to ~/.bashrc"
    else
        log_info "tmux auto-start already configured in ~/.bashrc"
    fi
}

# Main installation function
install_multiplexer() {
    if ! install_tmux_binary; then
        log_error "tmux installation failed - cannot setup tmux multiplexer"
        return 1
    fi
    
    create_tmux_config
    
    log_success "tmux multiplexer installation complete"
    log_info "Session will start automatically on SSH login"
    log_info "Use 'tmux new-session -s claudetainer' to start manually"
}