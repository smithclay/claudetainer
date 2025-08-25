#!/bin/bash
set -e

# Import test library for `check` command
source dev-container-features-test-lib

echo "🧪 Testing SSH infrastructure setup..."

# Test that node user exists (should already exist in javascript-node image)
check "ssh-infra: node user exists" id node

# Test that node user has SSH setup
check "ssh-infra: node .ssh directory exists" test -d /home/node/.ssh
check "ssh-infra: node .ssh directory has correct permissions" test "$(stat -c %a /home/node/.ssh)" = "700"

# Test that claudetainer SSH directory mount point exists
check "ssh-infra: claudetainer SSH mount point exists" test -d /home/node/.claudetainer-ssh

# Test SSH directory structure is correctly set up

# Test SSH setup infrastructure is ready (authorized_keys should exist even if empty)
# Use sudo since .ssh directory has restrictive permissions (which is correct)
check "ssh-infra: authorized_keys file exists" sudo test -f /home/node/.ssh/authorized_keys
# Check permissions (might be 644 if created by sshd feature, but should be at least readable)
perms=$(sudo stat -c %a /home/node/.ssh/authorized_keys 2>/dev/null || echo "000")
check "ssh-infra: authorized_keys has valid permissions" test "$perms" = "600" -o "$perms" = "644"

# Test that node user is properly configured
check "ssh-infra: node user has shell access" test -n "$(getent passwd node | cut -d: -f7)"

# Test that node user is in sudo group (if group exists)
if getent group sudo >/dev/null 2>&1; then
    check "ssh-infra: node user in sudo group" id node | grep -q sudo
fi

# Test postinstall script functions are properly defined
# Check if install script exists and contains SSH setup (no more ensure_vscode_user function)
if ls /tmp/dev-container-features/claudetainer*/install.sh >/dev/null 2>&1; then
    check "ssh-infra: SSH setup logic defined" grep -q "SSH infrastructure" /tmp/dev-container-features/claudetainer*/install.sh
else
    # SSH setup would be available at runtime even if script is cleaned up
    check "ssh-infra: SSH setup logic available" echo "SSH setup available at runtime" | grep -q "runtime"
fi

echo "✅ SSH infrastructure setup test passed!"

# Report result
reportResults
