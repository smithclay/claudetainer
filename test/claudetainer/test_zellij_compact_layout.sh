#!/bin/bash
set -e

# Import test library for `check` command
source dev-container-features-test-lib

echo "$HOME"

# Test: Zellij compact layout configuration
echo "🧪 Testing Zellij with claude-compact layout..."

# Test 1: Zellij binary is installed
check "zellij binary is installed" which zellij

# Test 2: Zellij configuration directory exists
check "zellij config directory exists" test -d "$HOME/.config/zellij"

# Test 3: Zellij configuration file exists
check "zellij configuration exists" test -f "$HOME/.config/zellij/config.kdl"

# Test 4: Claude-compact layout exists
check "claude-compact layout exists" test -f "$HOME/.config/zellij/layouts/claude-compact.kdl"

# Test 5: Auto-start script configured in bashrc
check "zellij auto-start configured in bashrc" grep -q "bashrc-multiplexer.sh" "$HOME/.bashrc"

# Test 6: Auto-start script exists
check "zellij auto-start script exists" test -f "$HOME/.claude/scripts/bashrc-multiplexer.sh"

# Test 7: Auto-start script contains compact layout configuration
check "auto-start script references compact layout" grep -q "claude-compact" "$HOME/.claude/scripts/bashrc-multiplexer.sh"

# Test 8: Compact layout contains expected structure
check "compact layout contains main tab" grep -q 'tab name="🤖"' "$HOME/.config/zellij/layouts/claude-compact.kdl"

# Test 9: Compact layout uses compact-bar plugin
check "compact layout uses compact-bar" grep -q "compact-bar" "$HOME/.config/zellij/layouts/claude-compact.kdl"

# Test 10: Layout is valid KDL syntax (basic validation)
check "compact layout is valid KDL syntax" bash -c 'head -1 ~/.config/zellij/layouts/claude-compact.kdl | grep -q "layout"'

echo "✅ Zellij compact layout tests passed!"
