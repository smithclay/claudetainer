#!/bin/bash
set -e

# Import test library for `check` command
source dev-container-features-test-lib

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

echo "✅ All tests passed!"

# Report result
reportResults