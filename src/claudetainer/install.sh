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
if ! command -v node >/dev/null || ! command -v npm >/dev/null; then
    source scripts/nodejs-helper.sh

    # Detect package manager
    PKG_MANAGER=$(detect_package_manager)
    echo "Detected package manager: $PKG_MANAGER"

    echo "Node.js or npm not found, attempting to install automatically..."
    install_nodejs "$PKG_MANAGER" || print_nodejs_requirement
fi

# Parse presets to install  
PRESETS="${INCLUDE:-base}"  # Use INCLUDE or default to "base"
if [ "$PRESETS" != "base" ] && [[ "$PRESETS" != *"base"* ]]; then
    PRESETS="base,$PRESETS"  # Prepend base if not already included
fi

echo "📦 Installing presets: $PRESETS"

# Apply each preset
IFS=',' read -ra PRESET_LIST <<< "$PRESETS"
for preset in "${PRESET_LIST[@]}"; do
    preset=$(echo "$preset" | xargs)  # trim whitespace
    preset_dir="presets/$preset"
    
    if [ ! -d "$preset_dir" ]; then
        echo "⚠️  Preset '$preset' not found, skipping"
        continue
    fi
    
    echo "   ✓ Applying $preset preset"
    
    # Copy commands and hooks (last preset wins for conflicts)
    if [ -d "$preset_dir/commands" ]; then
        echo "     📁 Installing commands from $preset"
        cp -r "$preset_dir/commands/"* "$TARGET_HOME/.claude/commands/"
    fi
    if [ -d "$preset_dir/hooks" ]; then
        echo "     🪝 Installing hooks from $preset"
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
        claude_file="presets/$preset/CLAUDE.md"
        if [ -f "$claude_file" ]; then
            echo "## From $preset preset:"
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
    settings_file="presets/$preset/settings.json"
    [ -f "$settings_file" ] && settings_files="$settings_files $settings_file"
done

if [ -n "$settings_files" ]; then
    echo "🔧 Merging settings..."
    node "lib/merge-json.js" $settings_files "$TARGET_HOME/.claude/settings.json"
fi

# Fix ownership if running as root and target user is different
if [ "$(whoami)" = "root" ] && [ "$TARGET_USER" != "root" ] && [ "$TARGET_USER" != "$(whoami)" ]; then
    echo "🔐 Setting ownership for user $TARGET_USER..."
    chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.claude" 2>/dev/null || true
fi

echo "✅ Claudetainer installed successfully!"
echo "💡 Try running: /hello"