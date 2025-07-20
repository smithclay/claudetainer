#!/bin/bash
set -eu

# Print error message about requiring Node.js feature
print_nodejs_requirement() {
    cat <<EOF

ERROR: Node.js and npm are required but could not be installed!
Please add the Node.js feature to your devcontainer.json:

  "features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/anthropics/devcontainer-features/claude-code:1": {}
  }

EOF
    exit 1
}

# Function to detect the package manager and OS type
detect_package_manager() {
    for pm in apt-get apk dnf yum; do
        if command -v $pm >/dev/null; then
            case $pm in
                apt-get) echo "apt" ;;
                *) echo "$pm" ;;
            esac
            return 0
        fi
    done
    echo "unknown"
    return 1
}

# Function to install packages using the appropriate package manager
install_packages() {
    local pkg_manager="$1"
    shift
    local packages="$@"
    
    case "$pkg_manager" in
        apt)
            apt-get update
            apt-get install -y $packages
            ;;
        apk)
            apk add --no-cache $packages
            ;;
        dnf|yum)
            $pkg_manager install -y $packages
            ;;
        *)
            echo "WARNING: Unsupported package manager. Cannot install packages: $packages"
            return 1
            ;;
    esac
    
    return 0
}

# Function to install Node.js
install_nodejs() {
    local pkg_manager="$1"
    
    echo "Installing Node.js using $pkg_manager..."
    
    case "$pkg_manager" in
        apt)
            # Debian/Ubuntu - install more recent Node.js LTS
            install_packages apt "ca-certificates curl gnupg"
            mkdir -p /etc/apt/keyrings
            curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
            echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
            apt-get update
            apt-get install -y nodejs
            ;;
        apk)
            # Alpine
            install_packages apk "nodejs npm"
            ;;
        dnf)
            # Fedora/RHEL
            install_packages dnf "nodejs npm"
            ;;
        yum)
            # CentOS/RHEL
            curl -sL https://rpm.nodesource.com/setup_18.x | bash -
            yum install -y nodejs
            ;;
        *)
            echo "ERROR: Unsupported package manager for Node.js installation"
            return 1
            ;;
    esac
    
    # Verify installation
    if command -v node >/dev/null && command -v npm >/dev/null; then
        echo "Successfully installed Node.js and npm"
        return 0
    else
        echo "Failed to install Node.js and npm"
        return 1
    fi
}

setup_notification_channel() {
    mkdir -p "$HOME/.config/claudetainer"
    # Create the notification channel configuration
    TOPIC="claudetainer-${devcontainerId:-default}"
    cat <<EOF >"$HOME/.config/claudetainer/ntfy.yaml"
ntfy_topic: $TOPIC
ntfy_server: https://ntfy.sh
EOF
    echo "Notification channel configured at $HOME/.config/claudetainer/ntfy.yaml to topic '$TOPIC'"
}

echo "Activating feature claudetainer..."

# Validate Claude Code is available
if [ ! -d "$HOME/.claude" ]; then
    echo "Warning: Claude Code directory not found at $HOME/.claude"
fi

# Create Claude directories
mkdir -p "$HOME/.claude/commands"
mkdir -p "$HOME/.claude/hooks"

# Detect package manager
PKG_MANAGER=$(detect_package_manager)
echo "Detected package manager: $PKG_MANAGER"

# Try to install Node.js if it's not available
if ! command -v node >/dev/null || ! command -v npm >/dev/null; then
    echo "Node.js or npm not found, attempting to install automatically..."
    install_nodejs "$PKG_MANAGER" || print_nodejs_requirement
fi

# For Phase 1: Only install base preset
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESET_DIR="$SCRIPT_DIR/presets/base"

if [ -d "$PRESET_DIR" ]; then
    # Copy commands
    cp -r "$PRESET_DIR/commands/"* "$HOME/.claude/commands/" 2>/dev/null || true
    
    # Copy hooks
    cp -r "$PRESET_DIR/hooks/"* "$HOME/.claude/hooks/" 2>/dev/null || true

    # Copy settings (minimal for Phase 1)
    cp "$PRESET_DIR/settings.json" "$HOME/.claude/settings.json" 2>/dev/null || true
    
    echo "✓ Base preset installed"
else
    echo "Error: Base preset not found at $PRESET_DIR"
    exit 1
fi

setup_notification_channel

echo "✓ Claudetainer installed successfully!"
echo "Try running: /hello"

