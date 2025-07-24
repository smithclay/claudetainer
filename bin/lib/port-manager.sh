#!/bin/bash
# Port Manager Library - Port allocation, validation, and persistence

# Calculate base port from project path hash
pm_calculate_project_base_port() {
    local hash=$(echo "$PWD" | shasum | head -c8)
    local port=$((2220 + (0x$hash % 80)))
    echo $port
}

# Check if a port is truly available using multiple methods
pm_is_port_available() {
    local port=$1

    # Method 1: netcat check
    if nc -z localhost "$port" 2>/dev/null; then
        return 1 # Port is in use
    fi

    # Method 2: lsof check (if available)
    if ui_command_exists lsof; then
        if lsof -i :"$port" >/dev/null 2>&1; then
            return 1 # Port is in use
        fi
    fi

    # Method 3: netstat check (if available and lsof not available)
    if ! ui_command_exists lsof && ui_command_exists netstat; then
        if netstat -ln 2>/dev/null | grep -q ":$port "; then
            return 1 # Port is in use
        fi
    fi

    # Method 4: Check if any Docker containers are using this port
    if ui_command_exists docker; then
        if docker ps --format "table {{.Ports}}" 2>/dev/null | grep -q ":$port->"; then
            return 1 # Port is in use by Docker
        fi
    fi

    return 0 # Port appears to be available
}

# Find next available port starting from base
pm_find_available_port() {
    local base_port=$1
    local attempts=0
    local max_attempts=80 # 2220-2299 range

    for ((port = base_port; port <= 2299 && attempts < max_attempts; port++, attempts++)); do
        if pm_is_port_available $port; then
            echo $port
            return 0
        fi
    done

    # If we've exhausted the range, try a second pass with a small delay
    # This handles race conditions where ports become available
    sleep 0.1
    for ((port = 2220; port <= 2299; port++)); do
        if pm_is_port_available $port; then
            echo $port
            return 0
        fi
    done

    return 1
}

# Get the current project's port (read-only, doesn't allocate)
pm_get_current_project_port() {
    local port_file=".devcontainer/.claudetainer-port"

    # First try: read from port file
    if [[ -f "$port_file" ]]; then
        local saved_port=$(cat "$port_file" 2>/dev/null | tr -d '\n\r ')
        # Validate port is a number in valid range
        if [[ "$saved_port" =~ ^[0-9]+$ ]] && [[ "$saved_port" -ge 2220 ]] && [[ "$saved_port" -le 2299 ]]; then
            echo "$saved_port"
            return 0
        fi
    fi

    # Second try: extract port from running container
    local container_name=$(docker ps --filter "label=devcontainer.local_folder=$(pwd)" --format "{{.Names}}" | head -1)
    if [[ -n "$container_name" ]]; then
        local container_port=$(docker inspect "$container_name" --format '{{index .Config.Labels "devcontainer.ssh_port"}}' 2>/dev/null)
        if [[ "$container_port" =~ ^[0-9]+$ ]] && [[ "$container_port" -ge 2220 ]] && [[ "$container_port" -le 2299 ]]; then
            # Recreate port file for future use
            mkdir -p .devcontainer 2>/dev/null
            echo "$container_port" >"$port_file" 2>/dev/null
            echo "$container_port"
            return 0
        fi
    fi

    # Third try: scan for active container ports in our range
    local project_containers=$(docker ps --filter "label=devcontainer.local_folder=$(pwd)" --format "{{.Names}}")
    if [[ -n "$project_containers" ]]; then
        for container in $project_containers; do
            local host_ports=$(docker port "$container" 2>/dev/null | grep -E '^22[0-9]{2}/' | cut -d: -f2)
            for port in $host_ports; do
                if [[ "$port" -ge 2220 ]] && [[ "$port" -le 2299 ]]; then
                    # Recreate port file for future use
                    mkdir -p .devcontainer 2>/dev/null
                    echo "$port" >"$port_file" 2>/dev/null
                    echo "$port"
                    return 0
                fi
            done
        done
    fi

    # Final fallback
    echo "2223"
}

# Get or allocate port for current project
pm_get_project_port() {
    local port_file=".devcontainer/.claudetainer-port"
    local lock_file=".devcontainer/.claudetainer-port.lock"

    # Create .devcontainer directory if it doesn't exist
    if ! mkdir -p .devcontainer 2>/dev/null; then
        ui_print_error "Cannot create .devcontainer directory"
        return 1
    fi

    # Use file locking to prevent race conditions
    (
        # Acquire lock with 10 second timeout
        if ui_command_exists flock; then
            flock -w 10 200 || {
                ui_print_error "Could not acquire port allocation lock"
                return 1
            }
        fi

        # Check existing port file (inside lock)
        if [[ -f "$port_file" ]]; then
            local saved_port=$(cat "$port_file" 2>/dev/null | tr -d '\n\r ')
            # Validate port format and range
            if [[ "$saved_port" =~ ^[0-9]+$ ]] && [[ "$saved_port" -ge 2220 ]] && [[ "$saved_port" -le 2299 ]]; then
                # Check if saved port is still available for this project to use
                # If port is in use by our own container, that's fine - we want to reuse it
                local our_container=$(docker ps --filter "label=devcontainer.local_folder=$(pwd)" --filter "label=devcontainer.ssh_port=$saved_port" --format "{{.Names}}" | head -1)
                if [[ -n "$our_container" ]] || pm_is_port_available "$saved_port"; then
                    echo "$saved_port"
                    return 0
                fi
            fi
        fi

        # Allocate new port
        local base_port=$(pm_calculate_project_base_port)
        local available_port=$(pm_find_available_port "$base_port")

        if [[ -n "$available_port" ]]; then
            # Atomic write using temporary file
            local temp_file="${port_file}.tmp.$$"
            if echo "$available_port" >"$temp_file" && mv "$temp_file" "$port_file"; then
                echo "$available_port"
                return 0
            else
                rm -f "$temp_file" 2>/dev/null
                ui_print_error "Failed to write port allocation file"
                return 1
            fi
        else
            ui_print_error "No available ports in range 2220-2299"
            return 1
        fi

    ) 200>"$lock_file"

    local result=$?
    rm -f "$lock_file" 2>/dev/null
    return $result
}

# Diagnostic function to show port allocation status
pm_show_port_status() {
    local port_file=".devcontainer/.claudetainer-port"
    local current_port=$(pm_get_current_project_port)
    local base_port=$(pm_calculate_project_base_port)

    echo "Port Allocation Status for $(pwd):"
    echo "========================================"
    echo "Project hash base port: $base_port"
    echo "Current allocated port: $current_port"
    echo

    if [[ -f "$port_file" ]]; then
        echo "Port file exists: $port_file"
        local file_content=$(cat "$port_file" 2>/dev/null)
        echo "Port file content: '$file_content'"
    else
        echo "Port file missing: $port_file"
    fi
    echo

    echo "Container status:"
    local containers=$(docker ps --filter "label=devcontainer.local_folder=$(pwd)" --format "{{.Names}}\t{{.Status}}\t{{.Ports}}")
    if [[ -n "$containers" ]]; then
        echo "$containers"
    else
        echo "No running containers found for this directory"
    fi
    echo

    echo "Port availability check:"
    if pm_is_port_available "$current_port"; then
        echo "Port $current_port: AVAILABLE"
    else
        echo "Port $current_port: IN USE"
        # Show what's using it
        if ui_command_exists lsof; then
            local process=$(lsof -i :"$current_port" 2>/dev/null | grep LISTEN)
            if [[ -n "$process" ]]; then
                echo "Used by: $process"
            fi
        fi
    fi
}
