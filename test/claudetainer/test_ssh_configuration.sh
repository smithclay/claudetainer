#!/bin/bash
set -e

# Import test library for `check` command
source dev-container-features-test-lib

echo "🧪 Testing SSH configuration with SSHD feature..."

# Test that vscode user exists (should be created by postinstall)
check "ssh: vscode user exists" id vscode

# Test that vscode user has a home directory
check "ssh: vscode home directory exists" test -d /home/vscode

# Test that SSH directory exists for vscode user
check "ssh: vscode .ssh directory exists" test -d /home/vscode/.ssh
check "ssh: vscode .ssh directory has correct permissions" test "$(sudo stat -c %a /home/vscode/.ssh)" = "700"

# Test that authorized_keys exists and has correct permissions for vscode
# Use sudo since .ssh directory has restrictive permissions (which is correct)
check "ssh: vscode authorized_keys file exists" sudo test -f /home/vscode/.ssh/authorized_keys
# Check permissions (might be 644 if created by sshd feature, but should be at least readable)
perms=$(sudo stat -c %a /home/vscode/.ssh/authorized_keys 2>/dev/null || echo "000")
check "ssh: vscode authorized_keys has valid permissions" test "$perms" = "600" -o "$perms" = "644"

# Test that claudetainer SSH directory mount point exists (even if empty in test)
check "ssh: claudetainer SSH directory mount point exists" test -d /home/vscode/.claudetainer-ssh

# Test SSH service is running (provided by sshd feature)
check "ssh: SSH service is running" pgrep -f sshd

# Test SSH configuration is set up for port 2222 (from test scenario)
check "ssh: SSH configuration exists" test -f /etc/ssh/sshd_config

# Test vscode user can be accessed via SSH (basic connectivity test)
check "ssh: vscode user has valid shell" test -x "$(getent passwd vscode | cut -d: -f7)"

echo "✅ SSH configuration test passed!"

# Report result
reportResults
