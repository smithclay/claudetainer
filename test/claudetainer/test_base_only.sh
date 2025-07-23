#!/bin/bash
set -e

# Import test library for `check` command
source dev-container-features-test-lib

echo $HOME

ls -la ~/.claude

echo "🧪 Testing base preset only..."

# Test that base preset files are installed
check "base: hello command exists" test -f ~/.claude/commands/hello.md
check "base: settings.json exists" test -f ~/.claude/settings.json
check "base: CLAUDE.md exists" test -f ~/.claude/CLAUDE.md
check "base: hooks directory exists" test -d ~/.claude/hooks

# Test content of base files
check "base: hello command has correct content" grep -q "Hello from Claudetainer" ~/.claude/commands/hello.md
check "base: CLAUDE.md contains base preset" grep -q "From base preset" ~/.claude/CLAUDE.md

# Test that python-specific files are NOT present
check "base: no python hello command" test ! -f ~/.claude/commands/hello-python.md

# Test settings.json structure
check "base: settings contains model field" grep -q '"model"' ~/.claude/settings.json
check "base: settings contains PostToolUse hook" grep -q '"PostToolUse"' ~/.claude/settings.json

echo "✅ Base only test passed!"

# Report result
reportResults
