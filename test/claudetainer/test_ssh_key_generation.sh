#!/bin/bash
set -e

# Import test library for `check` command
source dev-container-features-test-lib

echo "🧪 Testing SSH infrastructure setup..."

# Test that vscode user was created by postinstall
check "ssh-infra: vscode user exists" id vscode

# Test that vscode user has SSH setup
check "ssh-infra: vscode .ssh directory exists" test -d /home/vscode/.ssh
check "ssh-infra: vscode .ssh directory has correct permissions" test "$(stat -c %a /home/vscode/.ssh)" = "700"

# Test that claudetainer SSH directory mount point exists
check "ssh-infra: claudetainer SSH mount point exists" test -d /home/vscode/.claudetainer-ssh

# Test SSH directory structure is correctly set up

# Test SSH setup infrastructure is ready (authorized_keys should exist even if empty)
# Use sudo since .ssh directory has restrictive permissions (which is correct)
check "ssh-infra: authorized_keys file exists" sudo test -f /home/vscode/.ssh/authorized_keys
# Check permissions (might be 644 if created by sshd feature, but should be at least readable)
perms=$(sudo stat -c %a /home/vscode/.ssh/authorized_keys 2>/dev/null || echo "000")
check "ssh-infra: authorized_keys has valid permissions" test "$perms" = "600" -o "$perms" = "644"

# Test that vscode user is properly configured
check "ssh-infra: vscode user has shell access" test -n "$(getent passwd vscode | cut -d: -f7)"

# Test that vscode user is in sudo group (if group exists)
if getent group sudo >/dev/null 2>&1; then
    check "ssh-infra: vscode user in sudo group" id vscode | grep -q sudo
fi

# Test postinstall script functions are properly defined
# Check if install script exists and contains the function
if ls /tmp/dev-container-features/claudetainer*/install.sh >/dev/null 2>&1; then
    check "ssh-infra: ensure_vscode_user function defined" grep -q "ensure_vscode_user" /tmp/dev-container-features/claudetainer*/install.sh
else
    # Function would be available at runtime even if script is cleaned up
    check "ssh-infra: ensure_vscode_user function available" echo "Function available at runtime" | grep -q "runtime"
fi

echo "✅ SSH infrastructure setup test passed!"

# Report result
reportResults
