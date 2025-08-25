#!/bin/bash
# SSH Command - SSH connection management

# SSH into running container
cmd_ssh() {
    # Get the project's SSH port
    local port_file=".devcontainer/claudetainer/.claudetainer-port"
    local port=2223 # fallback port

    if [[ -f $port_file ]]; then
        port=$(cat "$port_file")
    fi

    # Check if container is running by trying to connect
    if ! nc -z localhost "$port" 2>/dev/null; then
        ui_print_error "Container not running or SSH not available on port $port"
        echo "Run 'claudetainer up' first to start the container"
        return 1
    fi

    ui_print_info "Connecting to container via SSH on port $port..."
    ui_print_info "The container will automatically start a multiplexer session with claude and usage windows"

    # Get SSH connection arguments (includes private key if available)
    local ssh_key_args
    ssh_key_args=$(ssh_get_connection_args)

    # Build SSH command arrays to avoid quoting issues
    local ssh_base_cmd=("ssh" "-p" "$port" "-o" "StrictHostKeyChecking=no" "-o" "UserKnownHostsFile=/dev/null" "-o" "GlobalKnownHostsFile=/dev/null" "-o" "LogLevel=ERROR")

    # Try key-based authentication first if key is available
    if [[ -n $ssh_key_args ]]; then
        ui_print_info "Using claudetainer SSH key for authentication"

        # Add key arguments to the command array
        local ssh_with_key_cmd=("${ssh_base_cmd[@]}")
        # shellcheck disable=SC2206
        ssh_with_key_cmd+=($ssh_key_args)

        # Test key-based authentication first
        if "${ssh_with_key_cmd[@]}" -o BatchMode=yes -o ConnectTimeout=5 vscode@localhost exit 2>/dev/null; then
            # Key auth works, connect normally
            "${ssh_with_key_cmd[@]}" vscode@localhost
            return 0
        else
            ui_print_warning "SSH key authentication failed, attempting to setup SSH keys in container..."

            # Try to setup SSH keys using password authentication
            if "${ssh_base_cmd[@]}" -o ConnectTimeout=10 vscode@localhost "sudo /workspaces/.devcontainer/claudetainer/setup-ssh-keys.sh" 2>/dev/null; then
                ui_print_success "SSH keys configured! Connecting with key authentication..."
                "${ssh_with_key_cmd[@]}" vscode@localhost
                return 0
            else
                ui_print_warning "Could not setup SSH keys automatically, falling back to password authentication"
            fi
        fi
    else
        ui_print_info "SSH key not found, falling back to password authentication"
    fi

    # Fall back to password authentication
    "${ssh_base_cmd[@]}" vscode@localhost
}
