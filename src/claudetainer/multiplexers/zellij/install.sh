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
    command -v zellij > /dev/null 2>&1
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

    if command -v curl > /dev/null 2>&1; then
        curl -fsSL "$download_url" | tar -xz -C "$temp_dir"
    elif command -v wget > /dev/null 2>&1; then
        wget -qO- "$download_url" | tar -xz -C "$temp_dir"
    else
        log_error "Neither curl nor wget found. Cannot download Zellij."
        return 1
    fi

    # Install binary (try with sudo, fallback to user bin)
    if sudo mv "$temp_dir/zellij" /usr/local/bin/zellij 2> /dev/null && sudo chmod +x /usr/local/bin/zellij 2> /dev/null; then
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
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
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

    # Copy main config file
    cp "multiplexers/zellij/config.kdl" "$ZELLIJ_CONFIG_DIR/config.kdl" 2> /dev/null || {
        log_error "Failed to copy default Zellij config"
        return 1
    }

    # Copy bundled layout files
    log_info "Installing bundled Zellij layouts..."
    for layout_file in multiplexers/zellij/layouts/*.kdl; do
        if [ -f "$layout_file" ]; then
            local layout_name=$(basename "$layout_file")
            cp "$layout_file" "$ZELLIJ_LAYOUTS_DIR/$layout_name" 2> /dev/null || {
                log_warning "Failed to copy layout: $layout_name"
                continue
            }
            log_info "  • Installed layout: $layout_name"
        fi
    done

    # Set proper ownership for all zellij configuration files
    local target_user="${TARGET_USER:-$(whoami)}"
    if [ "$target_user" != "$(whoami)" ] && command -v chown > /dev/null 2>&1; then
        chown -R "$target_user:$target_user" "$ZELLIJ_CONFIG_DIR" 2> /dev/null || {
            log_warning "Could not set ownership for Zellij configuration directory"
        }
    fi

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
            log_info "Falling back to bundled layout: tablet"
            export ZELLIJ_DEFAULT_LAYOUT="tablet"
        fi
    else
        # It's a bundled layout name
        case "$layout_spec" in
            tablet | phone)
                log_info "Using bundled layout: $layout_spec"
                export ZELLIJ_DEFAULT_LAYOUT="$layout_spec"
                ;;
            *)
                log_warning "Unknown bundled layout: $layout_spec"
                log_info "Available bundled layouts: tablet, phone"
                log_info "Falling back to: tablet"
                export ZELLIJ_DEFAULT_LAYOUT="tablet"
                ;;
        esac
    fi
}

# Setup auto-start for SSH sessions
setup_auto_start() {
    local target_home="${TARGET_HOME:-$HOME}"
    local bashrc="$target_home/.bashrc"

    log_info "Setting up Zellij auto-start..."

    # Create the auto-start script with layout substitution
    mkdir -p "$target_home/.claude/scripts"
    log_info "Setting up Zellij auto-start script with layout: ${ZELLIJ_DEFAULT_LAYOUT:-tablet}"
    
    # Substitute the layout placeholder in the template
    sed "s/__ZELLIJ_LAYOUT__/${ZELLIJ_DEFAULT_LAYOUT:-tablet}/g" "multiplexers/zellij/bash-multiplexer.sh" > "$target_home/.claude/scripts/bashrc-multiplexer.sh" || {
        log_error "Failed to create Zellij auto-start script"
        return 1
    }
    
    # Set proper ownership and permissions
    local target_user="${TARGET_USER:-$(whoami)}"
    if [ "$target_user" != "$(whoami)" ] && command -v chown > /dev/null 2>&1; then
        chown "$target_user:$target_user" "$target_home/.claude/scripts/bashrc-multiplexer.sh" 2> /dev/null || {
            log_warning "Could not set ownership for bashrc-multiplexer.sh"
        }
    fi
    chmod +x "$target_home/.claude/scripts/bashrc-multiplexer.sh"

    # Append to bashrc if not already present
    if ! grep -q "bashrc-multiplexer.sh" "$bashrc" 2> /dev/null; then
        {
            echo ""
            echo "# Claudetainer: Auto-start multiplexer session for remote connections"
            echo "source ~/.claude/scripts/bashrc-multiplexer.sh"
        } >> "$bashrc"
        log_success "Added Zellij auto-start to ~/.bashrc"
    else
        log_info "Zellij auto-start already configured in ~/.bashrc"
    fi
}

# Main installation function
install_multiplexer() {
    install_zellij_binary
    create_zellij_config

    log_success "Zellij multiplexer installation complete"
    log_info "Session will start automatically on SSH login with layout: ${ZELLIJ_DEFAULT_LAYOUT:-tablet}"
    log_info "Available layouts:"
    log_info "  • zellij --layout tablet --session claudetainer      # Enhanced 4-tab"
    log_info "  • zellij --layout phone --session claudetainer  # Compact 4-tab"
    if [ -n "${ZELLIJ_DEFAULT_LAYOUT:-}" ] && [ "${ZELLIJ_DEFAULT_LAYOUT:-}" != "tablet" ]; then
        log_info "  • zellij --layout $ZELLIJ_DEFAULT_LAYOUT --session claudetainer  # Custom/configured layout"
    fi
}
