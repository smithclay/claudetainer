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
	aarch64 | arm64) arch="aarch64-unknown-linux-musl" ;;
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
			echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >>"$HOME/.bashrc"
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
	cat >"$ZELLIJ_CONFIG_DIR/config.kdl" <<'EOF'
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

# Handle custom layout installation
handle_custom_layout() {
	local layout_spec="$1"

	# Check if it's a file path (contains / or starts with .)
	if [[ "$layout_spec" == *"/"* ]] || [[ "$layout_spec" == "."* ]]; then
		log_info "Installing custom layout from: $layout_spec"

		# Check if custom layout file exists
		if [ -f "$layout_spec" ]; then
			local layout_name
			layout_name=$(basename "$layout_spec" .kdl)
			cp "$layout_spec" "$ZELLIJ_LAYOUTS_DIR/${layout_name}.kdl"
			log_success "Installed custom layout: $layout_name"

			# Update the default layout to use custom one
			export ZELLIJ_DEFAULT_LAYOUT="$layout_name"
		else
			log_warning "Custom layout file not found: $layout_spec"
			log_info "Falling back to bundled layout: claude-dev"
			export ZELLIJ_DEFAULT_LAYOUT="claude-dev"
		fi
	else
		# It's a bundled layout name
		case "$layout_spec" in
		claude-dev | claude-compact | claudetainer)
			log_info "Using bundled layout: $layout_spec"
			export ZELLIJ_DEFAULT_LAYOUT="$layout_spec"
			;;
		*)
			log_warning "Unknown bundled layout: $layout_spec"
			log_info "Available bundled layouts: claude-dev, claude-compact, claudetainer"
			log_info "Falling back to: claude-dev"
			export ZELLIJ_DEFAULT_LAYOUT="claude-dev"
			;;
		esac
	fi
}

# Create Claudetainer layouts
create_claudetainer_layouts() {
	log_info "Creating Claudetainer layouts..."

	# Create layouts directory
	mkdir -p "$ZELLIJ_LAYOUTS_DIR"

	# Handle custom layout if specified
	local custom_layout="${ZELLIJ_LAYOUT:-claude-dev}"
	handle_custom_layout "$custom_layout"

	# Default Claudetainer layout (basic 2-tab)
	cat >"$ZELLIJ_LAYOUTS_DIR/claudetainer.kdl" <<'EOF'
// Claudetainer Layout - Basic 2-tab layout for Claude Code development
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
            command "bash"
            args "-c" "cd /workspaces && if [ -d * ] 2>/dev/null; then cd */; fi; clear; echo '🤖 Welcome to Claudetainer with Zellij!'; echo '💡 Switch tabs: Alt+h/l or Ctrl+t then 1/2/3/4'; echo '🚀 Start coding with: claude'; echo '📁 Working directory:' $(pwd); echo; echo '📋 Available layouts:'; echo '  • claude-dev     # 4-tab enhanced workflow'; echo '  • claude-compact # Minimal 4-tab layout'; echo '  • claudetainer   # This basic 2-tab layout'; echo; exec bash"
        }
    }
    
    // Usage monitoring tab  
    tab name="usage" {
        pane {
            command "bash"
            args "-c" "cd /workspaces && if [ -d * ] 2>/dev/null; then cd */; fi; echo '📊 Claude Code Usage Monitor'; echo 'Starting ccusage...'; echo; npx ccusage"
        }
    }
}
EOF

	# Copy enhanced development layout
	local script_dir
	script_dir="$(dirname "${BASH_SOURCE[0]}")"
	if [ -f "$script_dir/layouts/claude-dev.kdl" ]; then
		cp "$script_dir/layouts/claude-dev.kdl" "$ZELLIJ_LAYOUTS_DIR/claude-dev.kdl"
		log_success "Copied enhanced development layout"
	fi

	# Copy compact layout
	if [ -f "$script_dir/layouts/claude-compact.kdl" ]; then
		cp "$script_dir/layouts/claude-compact.kdl" "$ZELLIJ_LAYOUTS_DIR/claude-compact.kdl"
		log_success "Copied compact layout"
	fi

	log_success "Created Claudetainer layouts:"
	log_info "  • claudetainer    - Basic 2-tab layout"
	log_info "  • claude-dev      - Enhanced 4-tab development workflow"
	log_info "  • claude-compact  - Minimal 4-tab layout for small screens"
}

# Setup auto-start for SSH sessions
setup_auto_start() {
	local target_home="${TARGET_HOME:-$HOME}"
	local bashrc="$target_home/.bashrc"

	log_info "Setting up Zellij auto-start..."

	# Create the auto-start script
	mkdir -p "$target_home/.claude/scripts"
	log_info "Setting up Zellij auto-start script..."
	cat >"$target_home/.claude/scripts/bashrc-multiplexer.sh" <<EOF
#!/usr/bin/env bash

# bashrc-multiplexer.sh - Auto-start Zellij session for remote connections
# This gets appended to ~/.bashrc in the container

# Configure default Zellij layout
export ZELLIJ_DEFAULT_LAYOUT=\"${ZELLIJ_DEFAULT_LAYOUT:-claude-dev}\"

# Only run for interactive, remote SSH sessions, and not already in Zellij
if [[ \$- == *i* ]] && [[ -n "\${SSH_CONNECTION:-}" || -n "\${SSH_CLIENT:-}" ]] && [[ -z "\$ZELLIJ" ]]; then
    
    # Function to start regular shell with helpful message
    start_fallback_shell() {
        local reason="\$1"
        echo "⚠️  Zellij startup failed: \$reason"
        echo "🐚 Falling back to regular shell..."
        echo "💡 You can try manually: zellij --layout \${ZELLIJ_DEFAULT_LAYOUT:-claude-dev} --session claudetainer"
        echo "🔧 Or use basic shell commands as normal"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📁 Working directory: \$(pwd)"
        echo "🚀 Ready for development!"
        echo ""
        # Continue with normal shell - do NOT exec to avoid terminating session
        return 0
    }
    
    # Check if Zellij is available
    if ! command -v zellij >/dev/null 2>&1; then
        start_fallback_shell "Zellij not installed or not in PATH"
    else
        echo "🚀 Starting/attaching to claudetainer session with Zellij..."
        
        # Check if claudetainer session exists, attach if it does
        if zellij list-sessions 2>/dev/null | grep -q "claudetainer"; then
            echo "🔗 Attaching to existing claudetainer session..."
            # Try to attach, fallback to shell if it fails
            if ! zellij attach claudetainer 2>/dev/null; then
                start_fallback_shell "Failed to attach to existing session"
            fi
        else
            echo "🆕 Creating new claudetainer session with configured layout..."
            echo "💡 Available layouts: claudetainer \\(basic\\), claude-dev \\(enhanced\\), claude-compact \\(minimal\\)"
            
            # Determine which layout to use based on configuration
            local layout_to_use="\${ZELLIJ_DEFAULT_LAYOUT:-claude-dev}"
            
            # Check if the configured layout exists
            if [ -f ~/.config/zellij/layouts/"\$layout_to_use".kdl ]; then
                echo "✅ Using configured layout: \$layout_to_use"
            else
                # Fallback sequence: claude-dev -> claudetainer
                if [ -f ~/.config/zellij/layouts/claude-dev.kdl ]; then
                    layout_to_use="claude-dev"
                    echo "⚠️  Configured layout not found, falling back to: claude-dev"
                else
                    layout_to_use="claudetainer"
                    echo "ℹ️  Falling back to basic layout: claudetainer"
                fi
            fi
            
            # Try to start new session with error handling
            if ! zellij --new-session-with-layout "\$layout_to_use" -s claudetainer 2>/dev/null; then
                # If layout fails, try basic layout
                if [ "\$layout_to_use" = "claude-dev" ]; then
                    echo "⚠️  Enhanced layout failed, trying basic layout..."
                    if ! zellij --new-session-with-layout claudetainer -s claudetainer 2>/dev/null; then
                        start_fallback_shell "Both enhanced and basic layouts failed"
                    fi
                else
                    start_fallback_shell "Basic layout failed to start"
                fi
            fi
        fi
    fi
fi
EOF

	# Append to bashrc if not already present
	if ! grep -q "bashrc-multiplexer.sh" "$bashrc" 2>/dev/null; then
		{
			echo ""
			echo "# Claudetainer: Auto-start multiplexer session for remote connections"
			echo "source ~/.claude/scripts/bashrc-multiplexer.sh"
		} >>"$bashrc"
		log_success "Added Zellij auto-start to ~/.bashrc"
	else
		log_info "Zellij auto-start already configured in ~/.bashrc"
	fi
}

# Main installation function
install_multiplexer() {
	install_zellij_binary
	create_zellij_config
	create_claudetainer_layouts

	log_success "Zellij multiplexer installation complete"
	log_info "Session will start automatically on SSH login with layout: ${ZELLIJ_DEFAULT_LAYOUT:-claude-dev}"
	log_info "Available layouts:"
	log_info "  • zellij --layout claudetainer --session claudetainer    # Basic 2-tab"
	log_info "  • zellij --layout claude-dev --session claudetainer      # Enhanced 4-tab"
	log_info "  • zellij --layout claude-compact --session claudetainer  # Compact 4-tab"
	if [ -n "$ZELLIJ_DEFAULT_LAYOUT" ] && [ "$ZELLIJ_DEFAULT_LAYOUT" != "claude-dev" ]; then
		log_info "  • zellij --layout $ZELLIJ_DEFAULT_LAYOUT --session claudetainer  # Custom/configured layout"
	fi
}
