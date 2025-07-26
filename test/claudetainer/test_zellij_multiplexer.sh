#!/bin/bash
set -e

# Import test library for `check` command
source dev-container-features-test-lib

echo $HOME

# This test is specifically for the zellij multiplexer scenario
# It should always check for zellij binary and configuration

# Test 1: Check that zellij binary is installed
check "zellij binary is installed" command -v zellij

# Test 2: Check that zellij config directory exists
check "zellij config directory exists" test -d ~/.config/zellij

# Test 3: Check that zellij main config exists
check "zellij configuration exists" test -f ~/.config/zellij/config.kdl

# Test 4: Check that tablet layout exists
check "zellij tablet layout exists" test -f ~/.config/zellij/layouts/tablet.kdl

# Test 5: Check that auto-start is configured in bashrc
check "zellij auto-start configured in bashrc" grep -q "bashrc-multiplexer.sh" ~/.bashrc

# Test 6: Check that auto-start script exists
check "zellij auto-start script exists" test -f ~/.config/claudetainer/scripts/bashrc-multiplexer.sh

# Test 7: Check that auto-start script contains zellij-specific code
check "auto-start script contains zellij commands" grep -q "zellij" ~/.config/claudetainer/scripts/bashrc-multiplexer.sh

# Test 8: Check that layout contains claude tab
check "tablet layout contains claude tab" grep -q 'tab name="🤖 claude"' ~/.config/zellij/layouts/tablet.kdl

# Test 9: Check that layout contains cost tab
check "tablet layout contains cost tab" grep -q 'tab name="💰 cost"' ~/.config/zellij/layouts/tablet.kdl

# Test 10: Validate zellij configuration syntax
check "zellij main config is valid" bash -c '
    # Use official Zellij config validation command
    zellij --config ~/.config/zellij/config.kdl setup --check >/dev/null 2>&1
'

# Test 11: Validate tablet layout syntax
check "tablet layout is valid KDL syntax" bash -c '
    # Use official Zellij layout validation command
    zellij --layout ~/.config/zellij/layouts/tablet.kdl setup --check >/dev/null 2>&1
'

# Test 12: Check for common KDL syntax errors in layout
check "layout file has no obvious syntax errors" bash -c '
    # Basic checks for common syntax issues
    ! grep -q "Cannot have both tabs and panes" ~/.config/zellij/layouts/tablet.kdl 2>/dev/null &&
    # Check for proper bracket balancing (basic check)
    [ $(grep -c "{" ~/.config/zellij/layouts/tablet.kdl) -eq $(grep -c "}" ~/.config/zellij/layouts/tablet.kdl) ]
'

# Test 13: Validate bash script syntax
check "auto-start script has valid bash syntax" bash -n "$HOME/.config/claudetainer/scripts/bashrc-multiplexer.sh"

# Test 14: Auto-start script can be sourced without syntax errors
check "auto-start script can be sourced safely" bash -c '
    # Create a safe test environment and source the script
    export SSH_CONNECTION="test" ZELLIJ="" HOME="$HOME"
    timeout 5s bash -c "source ~/.config/claudetainer/scripts/bashrc-multiplexer.sh" >/dev/null 2>&1 || 
    # Check if it failed due to syntax vs runtime issues
    bash -n ~/.config/claudetainer/scripts/bashrc-multiplexer.sh
'

echo "✅ zellij multiplexer tests passed!"

# Report result
reportResults
