#!/bin/bash
# MOSH Command - Mobile Shell connection management

# Connect via MOSH to running container
cmd_mosh() {
    # Get the project's SSH port
    local port_file=".devcontainer/claudetainer/.claudetainer-port"
    local ssh_port=2223 # fallback port

    if [[ -f $port_file ]]; then
        ssh_port=$(cat "$port_file")
    fi

    # Calculate MOSH port (SSH port + 60000)
    local mosh_port=$((ssh_port + 60000))

    # Check if container is running by trying to connect to SSH port
    if ! nc -z localhost "$ssh_port" 2>/dev/null; then
        ui_print_error "Container not running or SSH not available on port $ssh_port"
        echo "Run 'claudetainer up' first to start the container"
        return 1
    fi

    ui_print_info "Connecting to container via MOSH on port $mosh_port..."
    ui_print_info "SSH connection will use port $ssh_port"
    ui_print_info "The container will automatically start a multiplexer session with claude and usage windows"

    # Get the correct username for this devcontainer (match SSH command)
    local ssh_user
    # Use same user detection as SSH command
    local devcontainer_file=".devcontainer/claudetainer/devcontainer.json"
    if [[ -f $devcontainer_file ]]; then
        ssh_user=$(grep -A 10 "ghcr.io/devcontainers/features/sshd" "$devcontainer_file" | grep '"USERNAME"' | sed 's/.*"USERNAME":[[:space:]]*"\([^"]*\)".*/\1/')
    fi
    ssh_user="${ssh_user:-vscode}" # fallback to vscode

    # Get SSH key arguments for authentication
    local ssh_key_args
    ssh_key_args=$(ssh_get_connection_args)

    # Build MOSH command with SSH key authentication
    local ssh_cmd="ssh -p $ssh_port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o LogLevel=ERROR $ssh_key_args"

    ui_print_info "Connecting as user: $ssh_user"
    mosh --ssh="$ssh_cmd" \
        --port="$mosh_port" \
        "$ssh_user@localhost"
}
