#!/bin/bash
set -e

# Import test library for `check` command
source dev-container-features-test-lib

echo "$HOME"

# This test is specifically for the tmux multiplexer scenario
# It should always check for tmux binary and configuration

# Test 1: Check that tmux binary is installed
check "tmux binary is installed" command -v tmux

# Test 2: Check that tmux configuration exists
check "tmux configuration exists" test -f ~/.tmux.conf

# Test 3: Check that auto-start is configured in bashrc
check "tmux auto-start configured in bashrc" grep -q "bashrc-multiplexer.sh" ~/.bashrc

# Test 4: Check that auto-start script exists
check "tmux auto-start script exists" test -f ~/.config/claudetainer/scripts/bashrc-multiplexer.sh

# Test 5: Check that auto-start script contains tmux-specific code
check "auto-start script contains tmux commands" grep -q "tmux" ~/.config/claudetainer/scripts/bashrc-multiplexer.sh

# Test 6: Validate bash script syntax
check "auto-start script has valid bash syntax" bash -n "$HOME/.config/claudetainer/scripts/bashrc-multiplexer.sh"

echo "✅ tmux multiplexer tests passed!"

# Report result
reportResults
