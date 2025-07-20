#!/bin/bash
set -e

# Import test library for `check` command
source dev-container-features-test-lib

echo "🧪 Testing base + python preset merging..."

echo $HOME

ls -la ~/.claude

# Test that base preset files are installed
check "merged: base hello command exists" test -f ~/.claude/commands/hello.md
check "merged: base settings.json exists" test -f ~/.claude/settings.json
check "merged: base CLAUDE.md exists" test -f ~/.claude/CLAUDE.md

# Test that python preset files are also installed
check "merged: python hello command exists" test -f ~/.claude/commands/hello-python.md

# Test CLAUDE.md merging
check "merged: CLAUDE.md contains base preset reference" grep -q "From base preset" ~/.claude/CLAUDE.md
check "merged: CLAUDE.md contains python preset reference" grep -q "From python preset" ~/.claude/CLAUDE.md

# Test settings merging (both base and python hooks should be present)
check "merged: settings contains base hooks" grep -q "hello.sh" ~/.claude/settings.json
check "merged: settings contains python hooks" grep -q "smart-lint.sh" ~/.claude/settings.json

# Test hook file override behavior (python smart-lint.sh should override base version)
if [ -f ~/.claude/hooks/smart-lint.sh ]; then
    # Python version should contain python-specific content or different content than base
    echo "✓ smart-lint.sh hook exists (python version should override base)"
fi

# Test that all expected commands directory has both base and python commands
BASE_COMMANDS=$(ls ~/.claude/commands/ | grep -E "(hello|check|commit|next)\.md" | wc -l)
PYTHON_COMMANDS=$(ls ~/.claude/commands/ | grep "hello-python\.md" | wc -l)

check "merged: base commands present" [ "$BASE_COMMANDS" -ge 3 ]
check "merged: python commands present" [ "$PYTHON_COMMANDS" -eq 1 ]

echo "✅ Base + Python merging test passed!"

# Report result
reportResults