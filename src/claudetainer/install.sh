#!/bin/bash
set -e

echo "🚀 Installing Claudetainer..."

# Determine target user's home directory
TARGET_HOME="${_REMOTE_USER_HOME:-$HOME}"
TARGET_USER="${_REMOTE_USER:-$(whoami)}"

# Create Claude directories
mkdir -p "$TARGET_HOME/.claude/commands"
mkdir -p "$TARGET_HOME/.claude/hooks"

# Try to install Node.js if it's not available
if ! command -v node > /dev/null || ! command -v npm > /dev/null; then
    source scripts/nodejs-helper.sh

    # Detect package manager
    PKG_MANAGER=$(detect_package_manager)
    echo "Detected package manager: $PKG_MANAGER"

    echo "Node.js or npm not found, attempting to install automatically..."
    if ! install_nodejs "$PKG_MANAGER"; then
        echo "Failed to install Node.js automatically"
        echo "Please install Node.js manually: https://nodejs.org/"
        exit 1
    fi
fi

# Parse presets to install
PRESETS="${INCLUDE:-base}" # Use INCLUDE or default to "base"
if [ "$PRESETS" != "base" ] && [[ "$PRESETS" != *"base"* ]]; then
    PRESETS="base,$PRESETS" # Prepend base if not already included
fi

echo "📦 Installing presets: $PRESETS"

# Function to fetch GitHub preset
fetch_github_preset() {
    local github_spec="$1"
    local temp_dir="$2"

    # Parse github:owner/repo/path format
    local repo_path="${github_spec#github:}"
    local owner_repo="${repo_path%%/*}"
    local preset_path="${repo_path#*/}"

    # If no path specified, default to root
    if [ "$preset_path" = "$owner_repo" ]; then
        preset_path=""
    else
        preset_path="${preset_path#*/}" # Remove repo name, keep path
    fi

    local clone_dir="$temp_dir/github-repos/$owner_repo"

    echo "     🌐 Fetching $github_spec..."

    # Clone repo if not already done
    if [ ! -d "$clone_dir" ]; then
        git clone --depth=1 "https://github.com/$owner_repo.git" "$clone_dir" > /dev/null 2>&1 || {
            echo "❌ Failed to fetch GitHub repo: $owner_repo"
            return 1
        }
    fi

    # Set up preset directory structure
    local source_dir="$clone_dir"
    if [ -n "$preset_path" ]; then
        source_dir="$clone_dir/$preset_path"
    fi

    if [ ! -d "$source_dir" ]; then
        echo "❌ Path '$preset_path' not found in repo $owner_repo"
        return 1
    fi

    # Copy to local presets directory
    local preset_name
    preset_name=$(basename "$preset_path")
    if [ -z "$preset_name" ] || [ "$preset_name" = "$owner_repo" ]; then
        preset_name="$owner_repo"
    fi

    local target_dir="presets/github-$preset_name"
    cp -r "$source_dir" "$target_dir"
    echo "$target_dir" # Return the local path for processing
}

# Check if git is available for GitHub presets
github_presets_exist=false
IFS=',' read -ra CHECK_PRESET_LIST <<< "$PRESETS"
for preset in "${CHECK_PRESET_LIST[@]}"; do
    preset=$(echo "$preset" | xargs)
    if [[ "$preset" == github:* ]]; then
        github_presets_exist=true
        break
    fi
done

if [ "$github_presets_exist" = true ]; then
    if ! command -v git > /dev/null 2>&1; then
        echo "❌ Error: git is required for GitHub presets but not found"
        echo "   Please install git or remove GitHub preset references"
        exit 1
    fi

    # Create temporary directory for GitHub repos
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT
fi

# Apply each preset
IFS=',' read -ra PRESET_LIST <<< "$PRESETS"
for preset in "${PRESET_LIST[@]}"; do
    preset=$(echo "$preset" | xargs) # trim whitespace

    # Handle GitHub presets
    if [[ "$preset" == github:* ]]; then
        if ! preset_dir=$(fetch_github_preset "$preset" "$temp_dir"); then
            echo "⚠️  Failed to fetch GitHub preset '$preset', skipping"
            continue
        fi
        preset_name="github-$(basename "${preset#github:*/*/}")"
        if [ -z "$preset_name" ] || [ "$preset_name" = "github-" ]; then
            preset_name="github-$(echo "${preset#github:}" | tr '/' '-')"
        fi
    else
        preset_dir="presets/$preset"
        preset_name="$preset"
    fi

    if [ ! -d "$preset_dir" ]; then
        echo "⚠️  Preset '$preset' not found, skipping"
        continue
    fi

    echo "   ✓ Applying $preset_name preset"

    # Copy commands and hooks (last preset wins for conflicts)
    if [ -d "$preset_dir/commands" ]; then
        echo "     📁 Installing commands from $preset_name"
        cp -r "$preset_dir/commands/"* "$TARGET_HOME/.claude/commands/"
    fi
    if [ -d "$preset_dir/hooks" ]; then
        echo "     🪝 Installing hooks from $preset_name"
        cp -r "$preset_dir/hooks/"* "$TARGET_HOME/.claude/hooks/"
    fi
done

# Merge CLAUDE.md files
{
    echo "# Claudetainer Configuration"
    echo ""
    echo "Merged from presets: $PRESETS"
    echo ""

    IFS=',' read -ra PRESET_LIST <<< "$PRESETS"
    for preset in "${PRESET_LIST[@]}"; do
        preset=$(echo "$preset" | xargs)

        # Handle GitHub presets for CLAUDE.md
        if [[ "$preset" == github:* ]]; then
            preset_name="github-$(basename "${preset#github:*/*/}")"
            if [ -z "$preset_name" ] || [ "$preset_name" = "github-" ]; then
                preset_name="github-$(echo "${preset#github:}" | tr '/' '-')"
            fi
            claude_file="presets/$preset_name/CLAUDE.md"
        else
            preset_name="$preset"
            claude_file="presets/$preset/CLAUDE.md"
        fi

        if [ -f "$claude_file" ]; then
            echo "## From $preset_name preset:"
            echo ""
            cat "$claude_file"
            echo ""
        fi
    done
} > "$TARGET_HOME/.claude/CLAUDE.md"

# Merge settings.json files
settings_files=""
IFS=',' read -ra PRESET_LIST <<< "$PRESETS"
for preset in "${PRESET_LIST[@]}"; do
    preset=$(echo "$preset" | xargs)

    # Handle GitHub presets for settings.json
    if [[ "$preset" == github:* ]]; then
        preset_name="github-$(basename "${preset#github:*/*/}")"
        if [ -z "$preset_name" ] || [ "$preset_name" = "github-" ]; then
            preset_name="github-$(echo "${preset#github:}" | tr '/' '-')"
        fi
        settings_file="presets/$preset_name/settings.json"
    else
        settings_file="presets/$preset/settings.json"
    fi

    [ -f "$settings_file" ] && settings_files="$settings_files $settings_file"
done

if [ -n "$settings_files" ]; then
    echo "🔧 Merging settings..."
    node "lib/merge-json.js" $settings_files "$TARGET_HOME/.claude/settings.json"
fi

# Fix ownership if running as root and target user is different
if [ "$(whoami)" = "root" ] && [ "$TARGET_USER" != "root" ] && [ "$TARGET_USER" != "$(whoami)" ]; then
    echo "🔐 Setting ownership for user $TARGET_USER..."
    chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.claude" 2> /dev/null || true
fi

# Install gitui if not already available
if ! command -v gitui > /dev/null 2>&1; then
    echo "📦 Installing gitui..."

    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64 | amd64)
            GITUI_ARCH="x86_64"
            ;;
        aarch64 | arm64)
            GITUI_ARCH="aarch64"
            ;;
        *)
            echo "⚠️  Unsupported architecture: $ARCH, skipping gitui installation"
            GITUI_ARCH=""
            ;;
    esac

    if [ -n "$GITUI_ARCH" ]; then
        GITUI_VERSION="v0.27.0"
        GITUI_URL="https://github.com/gitui-org/gitui/releases/download/${GITUI_VERSION}/gitui-linux-${GITUI_ARCH}.tar.gz"
        GITUI_TMP_DIR=$(mktemp -d)

        echo "     Downloading gitui for $GITUI_ARCH..."
        if curl -sL "$GITUI_URL" | tar -xz -C "$GITUI_TMP_DIR"; then
            # Create user bin directory if it doesn't exist
            mkdir -p "$TARGET_HOME/bin"

            # Move gitui binary to user's bin directory
            mv "$GITUI_TMP_DIR/gitui" "$TARGET_HOME/bin/"
            chmod +x "$TARGET_HOME/bin/gitui"

            # Fix ownership if needed
            if [ "$(whoami)" = "root" ] && [ "$TARGET_USER" != "root" ] && [ "$TARGET_USER" != "$(whoami)" ]; then
                chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/bin/gitui" 2> /dev/null || true
            fi

            echo "     ✓ gitui installed to $TARGET_HOME/bin/gitui"
        else
            echo "     ⚠️  Failed to download or extract gitui"
        fi

        # Cleanup
        rm -rf "$GITUI_TMP_DIR"
    fi
else
    echo "📦 gitui is already installed"
fi

# Setup multiplexer (zellij, tmux, or none)
MULTIPLEXER="${MULTIPLEXER:-zellij}"
ZELLIJ_LAYOUT="${ZELLIJ_LAYOUT:-tablet}"
echo "🔧 Setting up $MULTIPLEXER multiplexer..."

# Validate multiplexer choice
case "$MULTIPLEXER" in
    zellij | tmux | none) ;;
    *)
        echo "⚠️  Invalid multiplexer '$MULTIPLEXER', defaulting to 'zellij'"
        MULTIPLEXER="zellij"
        ;;
esac

# Export zellij layout for multiplexer scripts
if [ "$MULTIPLEXER" = "zellij" ]; then
    export ZELLIJ_LAYOUT
    echo "📋 Using Zellij layout: $ZELLIJ_LAYOUT"
fi

# Source multiplexer utilities
# shellcheck source=multiplexers/base.sh
source "multiplexers/base.sh"

# Setup the chosen multiplexer (graceful failure)
if ! setup_multiplexer "$MULTIPLEXER"; then
    echo "⚠️  Failed to setup $MULTIPLEXER multiplexer, continuing with basic installation"
else
    # Post-install steps only if multiplexer setup succeeded
    post_install_multiplexer
fi

# Setup custom workspace navigation and welcome message
echo "🏠 Setting up workspace navigation and welcome message..."

# Create .claude/scripts directory if it doesn't exist
mkdir -p "$TARGET_HOME/.claude/scripts"

# Install workspace setup script
cp "scripts/workspace-setup.sh" "$TARGET_HOME/.claude/scripts/workspace-setup.sh" 2>/dev/null || {
    echo "⚠️  Failed to copy workspace setup script (non-critical)"
}

# Set proper ownership and permissions for workspace setup script
if [ -f "$TARGET_HOME/.claude/scripts/workspace-setup.sh" ]; then
    if [ "$TARGET_USER" != "$(whoami)" ] && command -v chown > /dev/null 2>&1; then
        chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.claude/scripts/workspace-setup.sh" 2> /dev/null || {
            echo "⚠️  Could not set ownership for workspace-setup.sh"
        }
    fi
    chmod +x "$TARGET_HOME/.claude/scripts/workspace-setup.sh"
fi

# Add workspace setup to bashrc for all SSH sessions
if ! grep -q "workspace-setup.sh" "$TARGET_HOME/.bashrc" 2>/dev/null; then
    {
        echo ""
        echo "# Claudetainer: Workspace navigation and custom welcome"
        echo "source ~/.claude/scripts/workspace-setup.sh"
    } >> "$TARGET_HOME/.bashrc"
    echo "✅ Added workspace setup to ~/.bashrc"
else
    echo "📋 Workspace setup already configured in ~/.bashrc"
fi

# Disable system welcome messages for cleaner SSH experience
echo "🔇 Disabling system welcome messages..."

# Create or update .hushlogin to suppress system messages
touch "$TARGET_HOME/.hushlogin"

# Disable Ubuntu-specific welcome messages
if [ -f "/etc/update-motd.d" ]; then
    echo "📵 Found update-motd.d, attempting to disable system messages..."
    # We can't modify system files, but we can silence them with .hushlogin
fi

echo "✅ Claudetainer installed successfully!"
