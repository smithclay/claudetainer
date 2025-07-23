#!/usr/bin/env bash

# zellij/install.sh - Zellij multiplexer installation and configuration

set -euo pipefail

# Source base utilities
# shellcheck source=../base.sh
source "$(dirname "${BASH_SOURCE[0]}")/../base.sh"

# Zellij-specific configuration
ZELLIJ_VERSION="0.42.0"
ZELLIJ_CONFIG_DIR="${TARGET_HOME:-$HOME}/.config/zellij"
ZELLIJ_LAYOUTS_DIR="$ZELLIJ_CONFIG_DIR/layouts"

# Check if Zellij is available
is_multiplexer_available() {
    command -v zellij >/dev/null 2>&1
}

# Install Zellij
install_zellij_binary() {
    if is_multiplexer_available; then
        log_info "Zellij already installed: $(zellij --version)"
        return 0
    fi
    
    log_info "Installing Zellij $ZELLIJ_VERSION..."
    
    # Detect architecture
    local arch
    case "$(uname -m)" in
        x86_64) arch="x86_64-unknown-linux-musl" ;;
        aarch64|arm64) arch="aarch64-unknown-linux-musl" ;;
        *) 
            log_error "Unsupported architecture: $(uname -m)"
            return 1
            ;;
    esac
    
    # Download and install Zellij
    local download_url="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-${arch}.tar.gz"
    local temp_dir="/tmp/zellij-install"
    
    mkdir -p "$temp_dir"
    
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$download_url" | tar -xz -C "$temp_dir"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$download_url" | tar -xz -C "$temp_dir"
    else
        log_error "Neither curl nor wget found. Cannot download Zellij."
        return 1
    fi
    
    # Install binary (try with sudo, fallback to user bin)
    if sudo mv "$temp_dir/zellij" /usr/local/bin/zellij 2>/dev/null && sudo chmod +x /usr/local/bin/zellij 2>/dev/null; then
        log_info "Installed Zellij to /usr/local/bin/zellij"
    else
        # Fallback to user's bin directory
        mkdir -p "$HOME/.local/bin"
        mv "$temp_dir/zellij" "$HOME/.local/bin/zellij"
        chmod +x "$HOME/.local/bin/zellij"
        log_info "Installed Zellij to ~/.local/bin/zellij (add to PATH if needed)"
        
        # Try to add to PATH for current session
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            export PATH="$HOME/.local/bin:$PATH"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        fi
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    log_success "Zellij $ZELLIJ_VERSION installed successfully"
}

# Create Zellij configuration
create_zellij_config() {
    log_info "Creating Zellij configuration..."
    
    mkdir -p "$ZELLIJ_CONFIG_DIR" "$ZELLIJ_LAYOUTS_DIR"
    
    # Main configuration file
    cat > "$ZELLIJ_CONFIG_DIR/config.kdl" << 'EOF'
// Claudetainer Zellij Configuration
// Human-readable configuration for optimal remote development

// Keybindings - keep familiar but intuitive
keybinds {
    normal {
        // Quick access to common actions
        bind "Ctrl g" { SwitchToMode "Locked"; }
        bind "Ctrl p" { SwitchToMode "Pane"; }
        bind "Ctrl t" { SwitchToMode "Tab"; }
        bind "Ctrl s" { SwitchToMode "Session"; }
        
        // Quick navigation
        bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
        bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
        bind "Alt j" "Alt Down" { MoveFocus "Down"; }
        bind "Alt k" "Alt Up" { MoveFocus "Up"; }
        
        // Quick actions
        bind "Alt =" { Resize "Increase"; }
        bind "Alt -" { Resize "Decrease"; }
        bind "Alt [" { PreviousSwapLayout; }
        bind "Alt ]" { NextSwapLayout; }
    }
    
    locked {
        bind "Ctrl g" { SwitchToMode "Normal"; }
    }
}

// UI Configuration
ui {
    pane_frames {
        rounded_corners true
        hide_session_name false
    }
}

// Mouse support for easier navigation
mouse_mode true

// Copy to system clipboard
copy_clipboard "system"

// Default shell
default_shell "bash"

// Session serialization for persistence
session_serialization true

// Plugin configuration
plugins {
    tab-bar { path "tab-bar"; }
    status-bar { path "status-bar"; }
    strider { path "strider"; }
    compact-bar { path "compact-bar"; }
}

// Theme configuration - professional dark theme
themes {
    claudetainer {
        fg "#D8DEE9"
        bg "#2E3440" 
        black "#3B4252"
        red "#BF616A"
        green "#A3BE8C"
        yellow "#EBCB8B"
        blue "#81A1C1"
        magenta "#B48EAD"
        cyan "#88C0D0"
        white "#E5E9F0"
        orange "#D08770"
    }
}

// Use our custom theme
theme "claudetainer"
EOF
    
    log_success "Created Zellij configuration at $ZELLIJ_CONFIG_DIR/config.kdl"
}

# Create Claudetainer layout
create_claudetainer_layout() {
    log_info "Creating Claudetainer layout..."
    
    cat > "$ZELLIJ_LAYOUTS_DIR/claudetainer.kdl" << 'EOF'
// Claudetainer Layout - Optimized for remote Claude Code development
layout {
    default_tab_template {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        children
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }
    
    // Main development tab
    tab name="claude" focus=true {
        pane {
            cwd "/workspaces"
            command "bash"
            args "-c" "clear; echo '🤖 Welcome to Claudetainer with Zellij!'; echo '💡 Switch tabs: Alt+h/l or Ctrl+t then 1/2'; echo '🚀 Start coding with: claude'; echo; exec bash"
        }
    }
    
    // Usage monitoring tab  
    tab name="usage" {
        pane {
            cwd "/workspaces"
            command "bash"
            args "-c" "echo '📊 Claude Code Usage Monitor'; echo 'Starting ccusage...'; echo; npx ccusage"
        }
    }
}
EOF
    
    log_success "Created Claudetainer layout at $ZELLIJ_LAYOUTS_DIR/claudetainer.kdl"
}

# Setup auto-start for SSH sessions
setup_auto_start() {
    local target_home="${TARGET_HOME:-$HOME}"
    local bashrc="$target_home/.bashrc"
    
    log_info "Setting up Zellij auto-start..."
    
    # Create the auto-start script
    mkdir -p "$target_home/.claude/scripts"
    cat > "$target_home/.claude/scripts/bashrc-multiplexer.sh" << 'EOF'
#!/usr/bin/env bash

# bashrc-multiplexer.sh - Auto-start Zellij session for remote connections
# This gets appended to ~/.bashrc in the container

# Only run for interactive, remote SSH sessions, and not already in Zellij
if [[ $- == *i* ]] && [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" ]] && [[ -z "$ZELLIJ" ]]; then
    echo "🚀 Starting/attaching to claudetainer session with Zellij..."
    # Use attach --create for best practice session management
    # This will attach to existing session or create new one if it doesn't exist
    exec zellij attach --create claudetainer --layout claudetainer
fi
EOF
    
    # Append to bashrc if not already present
    if ! grep -q "bashrc-multiplexer.sh" "$bashrc" 2>/dev/null; then
        echo "" >> "$bashrc"
        echo "# Claudetainer: Auto-start multiplexer session for remote connections" >> "$bashrc"
        echo "source ~/.claude/scripts/bashrc-multiplexer.sh" >> "$bashrc"
        log_success "Added Zellij auto-start to ~/.bashrc"
    else
        log_info "Zellij auto-start already configured in ~/.bashrc"
    fi
}

# Main installation function
install_multiplexer() {
    install_zellij_binary
    create_zellij_config
    create_claudetainer_layout
    
    log_success "Zellij multiplexer installation complete"
    log_info "Session will start automatically on SSH login"
    log_info "Use 'zellij --layout claudetainer --session claudetainer' to start manually"
}