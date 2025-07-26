#!/bin/bash
# Build script - Creates single claudetainer executable from modular source

set -euo pipefail

BUILD_DIR="dist"
OUTPUT_FILE="$BUILD_DIR/claudetainer"

# Read version from devcontainer-feature.json as source of truth
if [[ -f "src/claudetainer/devcontainer-feature.json" ]]; then
    if command -v node > /dev/null 2>&1; then
        VERSION=$(node -e "console.log(JSON.parse(require('fs').readFileSync('src/claudetainer/devcontainer-feature.json', 'utf8')).version)" 2> /dev/null)
    else
        echo "❌ Node.js not found - required to read version from devcontainer-feature.json"
        exit 1
    fi
else
    echo "❌ devcontainer-feature.json not found"
    exit 1
fi

# Validate version was read successfully
if [[ -z "$VERSION" ]]; then
    echo "❌ Could not read version from devcontainer-feature.json"
    exit 1
fi

echo "🔨 Building claudetainer v$VERSION..."

# Create build directory
mkdir -p "$BUILD_DIR"

# Start with shebang and main script header
cat > "$OUTPUT_FILE" << 'EOF'
#!/bin/bash
set -euo pipefail

# Claudetainer CLI - Single-file distribution
# Generated from modular source - DO NOT EDIT DIRECTLY

EOF

# Add version information
echo "VERSION=\"$VERSION\"" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "📦 Injecting version: $VERSION"

# Embed library functions in dependency order
echo "# === EMBEDDED LIBRARIES ===" >> "$OUTPUT_FILE"
for lib in config ui validation port-manager docker-ops notifications devcontainer-gen; do
    lib_file="bin/lib/$lib.sh"
    if [[ -f "$lib_file" ]]; then
        echo "📦 Embedding library: $lib"
        echo "# Source: $lib_file" >> "$OUTPUT_FILE"
        # Remove shebang, set -e, and other script headers, keep functions
        sed -e '1,/^$/d' -e '/^set -/d' "$lib_file" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Embed command modules
echo "# === EMBEDDED COMMANDS ===" >> "$OUTPUT_FILE"
for cmd in doctor prereqs init up ssh rm list; do
    cmd_file="bin/commands/$cmd.sh"
    if [[ -f "$cmd_file" ]]; then
        echo "📦 Embedding command: $cmd"
        echo "# Source: $cmd_file" >> "$OUTPUT_FILE"
        # Remove shebang, set -e, and other script headers, keep functions
        sed -e '1,/^$/d' -e '/^set -/d' "$cmd_file" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Add main script logic (from streamlined main script)
echo "# === MAIN SCRIPT ===" >> "$OUTPUT_FILE"
# Skip the library loading and sourcing parts, just add the main dispatch logic
sed -n '/^# Main command dispatcher/,$ p' bin/claudetainer |
    # Remove the library loading parts
    sed '/load_library\|load_command\|source\|SCRIPT_DIR/d' |
    # Remove the load_commands_for function since everything is embedded
    sed '/^load_commands_for()/,/^}/d' |
    # Remove the call to load_commands_for
    sed '/load_commands_for/d' >> "$OUTPUT_FILE"

# Make executable
chmod +x "$OUTPUT_FILE"

echo "✅ Built: $OUTPUT_FILE"
echo "📊 Size: $(wc -c < "$OUTPUT_FILE") bytes ($(wc -l < "$OUTPUT_FILE") lines)"
echo "🧪 Testing build..."

# Quick smoke test
if "$OUTPUT_FILE" --version > /dev/null 2>&1; then
    echo "✅ Build test passed"

    # Test a few more commands
    echo "🔍 Testing additional commands..."

    if "$OUTPUT_FILE" --help > /dev/null 2>&1; then
        echo "✅ Help command works"
    else
        echo "❌ Help command failed"
        exit 1
    fi

    # Test prerequisite check (shouldn't fail the build)
    echo "🔍 Testing prereqs command..."
    "$OUTPUT_FILE" prereqs > /dev/null 2>&1 || echo "ℹ️  Prereqs check completed (expected to show missing deps)"

    echo "🎉 Build completed successfully!"
    echo ""
    echo "📋 Usage:"
    echo "  • Development: ./bin/claudetainer <command>"
    echo "  • Distribution: ./dist/claudetainer <command>"
    echo "  • Install: cp ./dist/claudetainer /usr/local/bin/claudetainer"
    echo ""
    echo "🔧 Size comparison:"
    echo "  • Modular: $(wc -l < bin/claudetainer) main + $(find bin/lib bin/commands -name "*.sh" | wc -l) modules"
    echo "  • Built: $(wc -l < "$OUTPUT_FILE") lines"

else
    echo "❌ Build test failed"
    echo "Debug: Testing basic execution..."
    "$OUTPUT_FILE" --version || true
    exit 1
fi
