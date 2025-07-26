#!/bin/bash
# SSH Command - SSH connection management

# SSH into running container
cmd_ssh() {
    # Get the project's SSH port
    local port_file=".devcontainer/.claudetainer-port"
    local port=2223 # fallback port

    if [[ -f "$port_file" ]]; then
        port=$(cat "$port_file")
    fi

    # Check if container is running by trying to connect
    if ! nc -z localhost "$port" 2> /dev/null; then
        ui_print_error "Container not running or SSH not available on port $port"
        echo "Run 'claudetainer up' first to start the container"
        return 1
    fi

    ui_print_info "Connecting to container via SSH on port $port..."
    ui_print_info "The container will automatically start a multiplexer session with claude and usage windows"
    ssh -p "$port" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o GlobalKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        vscode@localhost
}
