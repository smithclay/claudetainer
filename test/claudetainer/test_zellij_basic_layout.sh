#!/bin/bash
set -e

# Import test library for `check` command
source dev-container-features-test-lib

echo "$HOME"

# Test: Zellij basic layout configuration
echo "🧪 Testing Zellij with claudetainer layout..."

# Test 1: Zellij binary is installed
check "zellij binary is installed" which zellij

# Test 2: Zellij configuration directory exists
check "zellij config directory exists" test -d "$HOME/.config/zellij"

# Test 3: Zellij configuration file exists
check "zellij configuration exists" test -f "$HOME/.config/zellij/config.kdl"

# Test 4: Claudetainer layout exists
check "claudetainer layout exists" test -f "$HOME/.config/zellij/layouts/claudetainer.kdl"

# Test 5: Auto-start script configured in bashrc
check "zellij auto-start configured in bashrc" grep -q "bashrc-multiplexer.sh" "$HOME/.bashrc"

# Test 6: Auto-start script exists
check "zellij auto-start script exists" test -f "$HOME/.claude/scripts/bashrc-multiplexer.sh"

# Test 7: Auto-start script contains claudetainer layout configuration
check "auto-start script references claudetainer layout" grep -q "claudetainer" "$HOME/.claude/scripts/bashrc-multiplexer.sh"

# Test 8: Claudetainer layout contains expected tabs
check "claudetainer layout contains claude tab" grep -q 'tab name="claude"' "$HOME/.config/zellij/layouts/claudetainer.kdl"
check "claudetainer layout contains usage tab" grep -q 'tab name="usage"' "$HOME/.config/zellij/layouts/claudetainer.kdl"

# Test 9: Layout is valid KDL syntax (basic validation)
check "claudetainer layout is valid KDL syntax" bash -c 'head -1 ~/.config/zellij/layouts/claudetainer.kdl | grep -q "layout"'

# Test 10: Layout has basic structure
check "layout has focus on claude tab" grep -q 'focus=true' "$HOME/.config/zellij/layouts/claudetainer.kdl"

echo "✅ Zellij claudetainer layout tests passed!"
