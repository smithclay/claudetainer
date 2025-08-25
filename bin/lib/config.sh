#!/bin/bash
# Configuration Library - Default settings and configuration management

# Version information
VERSION="${VERSION:-0.1.1}"

# Default settings
config_get_default_multiplexer() {
    echo "zellij"
}

config_get_port_range_start() {
    echo "2220"
}

config_get_port_range_end() {
    echo "2299"
}

config_get_credentials_file() {
    echo "$HOME/.claudetainer-credentials.json"
}

config_get_ntfy_channel_file() {
    echo "$HOME/.claudetainer-ntfy-channel"
}

# Language-specific configuration
config_get_language_config() {
    local lang="$1"
    case "$lang" in
    python)
        echo "name:Python Claudetainer"
        echo "image:mcr.microsoft.com/devcontainers/python:3"
        echo "post_create:claude --version"
        ;;
    node)
        echo "name:Node.js Claudetainer"
        echo "image:mcr.microsoft.com/devcontainers/javascript-node:22-bookworm"
        echo "post_create:claude --version"
        ;;
    rust)
        echo "name:Rust Claudetainer"
        echo "image:mcr.microsoft.com/devcontainers/rust:1-bookworm"
        echo "post_create:claude --version"
        ;;
    go)
        echo "name:Go Claudetainer"
        echo "image:mcr.microsoft.com/devcontainers/go:1-bookworm"
        echo "post_create:claude --version"
        ;;
    shell)
        echo "name:Shell Script Claudetainer"
        echo "image:mcr.microsoft.com/devcontainers/base:bookworm"
        echo "post_create:sudo apt-get update && sudo apt-get install -y shellcheck && curl -L https://github.com/mvdan/sh/releases/download/v3.7.0/shfmt_v3.7.0_linux_amd64 -o /tmp/shfmt && sudo mv /tmp/shfmt /usr/local/bin/shfmt && sudo chmod +x /usr/local/bin/shfmt && claude --version"
        ;;
    base)
        echo "name:Base Claudetainer"
        echo "image:mcr.microsoft.com/devcontainers/base:bookworm"
        echo "post_create:claude --version"
        ;;
    esac
}

# Language-specific additional features
config_get_language_features() {
    local lang="$1"
    case "$lang" in
    python)
        echo '"ghcr.io/va-h/devcontainers-features/uv:1": {}'
        ;;
    node)
        # No additional features for node yet
        ;;
    rust)
        # No additional features for rust yet
        ;;
    go)
        # No additional features for go yet
        ;;
    shell)
        # No additional features for shell yet
        ;;
    base)
        # No additional features for base
        ;;
    esac
}

# Load user configuration if it exists
config_load_user_config() {
    local user_config="$HOME/.claudetainer/config"
    if [[ -f $user_config ]]; then
        # shellcheck disable=SC1090 # Dynamic source path by design
        source "$user_config" 2>/dev/null || true
    fi
}

# Initialize configuration
config_init() {
    config_load_user_config
}
