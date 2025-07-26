#!/bin/bash
set -e

# Import test library for `check` command
source dev-container-features-test-lib

echo $HOME

ls -la ~/.claude

# Test 1: Check that claudetainer installed successfully
check "claudetainer install script exists" test -f ~/.claude/commands/hello.md

# Test 2: Check that settings.json was created
check "claude settings created" test -f ~/.claude/settings.json

# Test 3: Check that hello command content is correct
check "hello command has correct content" grep -q "Hello from Claudetainer" ~/.claude/commands/hello.md

# Test 4: Check that directories were created
check "claude commands directory exists" test -d ~/.claude/commands
check "claude hooks directory exists" test -d ~/.claude/hooks

# Test 5: Verify settings.json is valid JSON (basic structure check)
check "settings.json contains model field" grep -q '"model"' ~/.claude/settings.json
check "settings.json contains permissions field" grep -q '"permissions"' ~/.claude/settings.json
check "settings.json contains PostToolUse hook" grep -q '"PostToolUse"' ~/.claude/settings.json
check "settings.json contains PostToolUse hook" grep -q '"Notification"' ~/.claude/settings.json

# Test 6: Validate syntax of generated shell scripts
check "settings.json is valid JSON" python3 -c "import json; json.load(open('$HOME/.claude/settings.json'))" 2> /dev/null

# Test 7: Check bash syntax of hook scripts
for hook_script in ~/.claude/hooks/*.sh; do
    if [ -f "$hook_script" ]; then
        check "hook script $(basename $hook_script) has valid bash syntax" bash -n "$hook_script"
    fi
done

# Test 8: Check multiplexer auto-start script if it exists
if [ -f ~/.config/claudetainer/scripts/bashrc-multiplexer.sh ]; then
    check "auto-start script has valid bash syntax" bash -n ~/.config/claudetainer/scripts/bashrc-multiplexer.sh
fi

# Test 9: Check that gitui was installed to user bin directory
check "gitui installed to user bin" test -f "$HOME/.local/bin/gitui"
check "gitui is executable" test -x "$HOME/.local/bin/gitui"

echo "✅ All tests passed!"

# Report result
reportResults
