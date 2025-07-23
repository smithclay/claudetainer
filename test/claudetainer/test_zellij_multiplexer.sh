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

# Test 4: Check that claudetainer layout exists
check "zellij claudetainer layout exists" test -f ~/.config/zellij/layouts/claudetainer.kdl

# Test 5: Check that auto-start is configured in bashrc
check "zellij auto-start configured in bashrc" grep -q "bashrc-multiplexer.sh" ~/.bashrc

# Test 6: Check that auto-start script exists
check "zellij auto-start script exists" test -f ~/.claude/scripts/bashrc-multiplexer.sh

# Test 7: Check that auto-start script contains zellij-specific code
check "auto-start script contains zellij commands" grep -q "zellij" ~/.claude/scripts/bashrc-multiplexer.sh

# Test 8: Check that layout contains claude tab
check "claudetainer layout contains claude tab" grep -q 'tab name="claude"' ~/.config/zellij/layouts/claudetainer.kdl

# Test 9: Check that layout contains usage tab
check "claudetainer layout contains usage tab" grep -q 'tab name="usage"' ~/.config/zellij/layouts/claudetainer.kdl

echo "✅ zellij multiplexer tests passed!"

# Report result
reportResults