#!/bin/bash
set -e

# Import test library for `check` command
source dev-container-features-test-lib

echo $HOME

# This test is specifically for the none multiplexer scenario
# It should check that no multiplexer is installed and simple environment is configured

# Test 1: Check that tmux is NOT installed (optional - it might be installed by base image)
# We don't fail if tmux exists, but we verify our config doesn't use it

# Test 2: Check that zellij is NOT installed (optional - it might be installed by base image)
# We don't fail if zellij exists, but we verify our config doesn't use it

# Test 3: Check that auto-start is configured in bashrc
check "auto-start configured in bashrc" grep -q "bashrc-multiplexer.sh" ~/.bashrc

# Test 4: Check that auto-start script exists
check "auto-start script exists" test -f ~/.config/claudetainer/scripts/bashrc-multiplexer.sh

# Test 5: Check that auto-start script does NOT contain tmux commands
check "auto-start script does not contain tmux commands" bash -c "! grep -q 'tmux' ~/.config/claudetainer/scripts/bashrc-multiplexer.sh"

# Test 6: Check that auto-start script does NOT contain zellij commands
check "auto-start script does not contain zellij commands" bash -c "! grep -q 'zellij' ~/.config/claudetainer/scripts/bashrc-multiplexer.sh"

# Test 7: Check that auto-start script contains welcome message
check "auto-start script contains welcome message" grep -q "Welcome to Claudetainer" ~/.config/claudetainer/scripts/bashrc-multiplexer.sh

# Test 8: Check that auto-start script mentions no multiplexer
check "auto-start script mentions no multiplexer" grep -q "No multiplexer configured" ~/.config/claudetainer/scripts/bashrc-multiplexer.sh

# Test 9: Check that auto-start script changes to workspaces directory
check "auto-start script changes to workspaces" grep -q "/workspaces" ~/.config/claudetainer/scripts/bashrc-multiplexer.sh

echo "✅ none multiplexer tests passed!"

# Report result
reportResults
