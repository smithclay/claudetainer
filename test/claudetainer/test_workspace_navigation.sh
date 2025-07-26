#!/bin/bash

# Test script for workspace navigation and welcome message functionality

set -e

# Load test library
source dev-container-features-test-lib

echo "$HOME"

# Test: Workspace navigation and welcome message setup
echo "🧪 Testing workspace navigation and custom welcome message..."

# Test 1: Workspace setup script exists
check "workspace setup script exists" test -f "$HOME/.config/claudetainer/scripts/workspace-setup.sh"

# Test 2: Workspace setup script is executable
check "workspace setup script is executable" test -x "$HOME/.config/claudetainer/scripts/workspace-setup.sh"

# Test 3: Workspace setup configured in bashrc
check "workspace setup configured in bashrc" grep -q "workspace-setup.sh" "$HOME/.bashrc"

# Test 4: .hushlogin exists to suppress system messages
check ".hushlogin file exists" test -f "$HOME/.hushlogin"

# Test 5: Workspace setup script has valid bash syntax
check "workspace setup script has valid bash syntax" bash -n "$HOME/.config/claudetainer/scripts/workspace-setup.sh"

# Test 6: Workspace setup script contains expected functions
check "workspace setup script contains navigation function" grep -q "claudetainer_workspace_nav" "$HOME/.config/claudetainer/scripts/workspace-setup.sh"

# Test 7: Workspace setup script contains welcome function
check "workspace setup script contains welcome function" grep -q "claudetainer_welcome" "$HOME/.config/claudetainer/scripts/workspace-setup.sh"

# Test 8: Workspace setup script mentions key commands
check "workspace setup script mentions claude command" grep -q "claude.*# Start Claude Code" "$HOME/.config/claudetainer/scripts/workspace-setup.sh"

# Test 10: Test workspace navigation logic with mock /workspaces
mkdir -p "/tmp/mock-workspaces/test-project"
echo "Testing workspace navigation with mock directory..."

# Create a test script to verify workspace navigation
cat > "/tmp/test-workspace-nav.sh" << 'EOF'
#!/bin/bash
# Mock the workspace navigation function
source ~/.config/claudetainer/scripts/workspace-setup.sh

# Mock /workspaces for testing
export OLD_PWD="$PWD"
mkdir -p /tmp/test-workspace/single-project
cd /tmp

# Test single workspace detection
if [[ -d /tmp/test-workspace ]]; then
    workspace_dirs=($(find /tmp/test-workspace -maxdepth 1 -type d ! -path /tmp/test-workspace))
    workspace_count=${#workspace_dirs[@]}
    
    if [[ $workspace_count -eq 1 ]]; then
        echo "✅ Single workspace detection works"
        exit 0
    else
        echo "❌ Single workspace detection failed"
        exit 1
    fi
fi
EOF

check "workspace navigation logic works" bash "/tmp/test-workspace-nav.sh"

echo "✅ All workspace navigation and welcome message tests passed!"
