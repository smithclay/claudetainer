#!/usr/bin/env bash

# base.sh - Common multiplexer interface and utilities
# Provides consistent interface for different terminal multiplexers

set -euo pipefail

# Common multiplexer interface - all multiplexers must implement these functions:
# - install_multiplexer() - Install and configure the multiplexer
# - setup_auto_start() - Configure auto-start on SSH login
# - get_session_name() - Return the session name to use
# - is_multiplexer_available() - Check if multiplexer is installed

# Multiplexer configuration
MULTIPLEXER="${MULTIPLEXER:-zellij}"
SESSION_NAME="claudetainer"
WORKSPACE_DIR="/workspaces"

# Common utilities
log_info() {
    echo "📋 $1" >&2
}

log_success() {
    echo "✅ $1" >&2
}

log_warning() {
    echo "⚠️  $1" >&2
}

log_error() {
    echo "❌ $1" >&2
}

# Get the multiplexer directory
get_multiplexer_dir() {
    local multiplexer="${1:-$MULTIPLEXER}"
    echo "$(dirname "${BASH_SOURCE[0]}")/$multiplexer"
}

# Load multiplexer-specific functions
load_multiplexer() {
    local multiplexer="${1:-$MULTIPLEXER}"
    local multiplexer_dir
    multiplexer_dir=$(get_multiplexer_dir "$multiplexer")
    
    if [[ ! -d "$multiplexer_dir" ]]; then
        log_error "Unsupported multiplexer: $multiplexer"
        return 1
    fi
    
    local install_script="$multiplexer_dir/install.sh"
    if [[ -f "$install_script" ]]; then
        # shellcheck source=/dev/null
        source "$install_script"
    else
        log_error "Missing install script for multiplexer: $multiplexer"
        return 1
    fi
}

# Install and configure multiplexer
setup_multiplexer() {
    local multiplexer="${1:-$MULTIPLEXER}"
    
    log_info "Setting up $multiplexer multiplexer..."
    
    if ! load_multiplexer "$multiplexer"; then
        log_warning "Failed to load $multiplexer multiplexer, falling back to 'none'"
        return 0
    fi
    
    # Call multiplexer-specific installation
    if command -v install_multiplexer >/dev/null 2>&1; then
        if ! install_multiplexer; then
            log_warning "$multiplexer installation failed, continuing without multiplexer"
            return 0
        fi
    else
        log_error "install_multiplexer function not found for $multiplexer"
        return 1
    fi
    
    # Setup auto-start if function exists
    if command -v setup_auto_start >/dev/null 2>&1; then
        setup_auto_start
    fi
    
    log_success "$multiplexer multiplexer setup complete"
}

# Check if multiplexer is available
check_multiplexer() {
    local multiplexer="${1:-$MULTIPLEXER}"
    
    if ! load_multiplexer "$multiplexer"; then
        return 1
    fi
    
    if command -v is_multiplexer_available >/dev/null 2>&1; then
        is_multiplexer_available
    else
        log_error "is_multiplexer_available function not found for $multiplexer"
        return 1
    fi
}

# Get session name for multiplexer
get_session_name() {
    echo "$SESSION_NAME"
}

# Common post-install steps
post_install_multiplexer() {
    local target_home="${TARGET_HOME:-$HOME}"
    
    # Set ownership if running as root
    if [[ "$(whoami)" = "root" ]] && [[ "$TARGET_USER" != "root" ]] && [[ -n "${TARGET_USER:-}" ]]; then
        chown -R "$TARGET_USER:$TARGET_USER" "$target_home/.config" 2>/dev/null || true
        chown -R "$TARGET_USER:$TARGET_USER" "$target_home/.claude" 2>/dev/null || true
    fi
}

# Validate multiplexer choice
validate_multiplexer() {
    local multiplexer="${1:-$MULTIPLEXER}"
    
    case "$multiplexer" in
        zellij|tmux|none)
            return 0
            ;;
        *)
            log_error "Invalid multiplexer: $multiplexer. Supported: zellij, tmux, none"
            return 1
            ;;
    esac
}