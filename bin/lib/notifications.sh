#!/bin/bash
# Notifications Library - Notification channel management

# Generate unique notification channel
notifications_generate_channel() {
    # Generate a short, easy-to-type unique channel using project path and timestamp
    local project_name=$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
    local hash=$(echo "$PWD$(date +%s)" | shasum | head -c6)
    echo "claude-${project_name}-${hash}"
}

# Ensure credentials file exists for container mounting
notifications_ensure_credentials_file() {
    local credentials_file=$(config_get_credentials_file)

    if [[ ! -f "$credentials_file" ]]; then
        ui_print_info "Creating empty credentials file at $credentials_file"
        echo '{}' > "$credentials_file"
        ui_print_success "Created $credentials_file"
    fi
}

# Setup notification channel and config
notifications_setup_channel() {
    local container_name="$1"
    local ntfy_channel_file=$(config_get_ntfy_channel_file)

    # Generate or reuse existing notification channel
    local ntfy_channel
    if [[ -f "$ntfy_channel_file" ]]; then
        ntfy_channel=$(cat "$ntfy_channel_file" 2> /dev/null | tr -d '\n\r ')
        ui_print_info "Using existing ntfy channel: $ntfy_channel"
    else
        ntfy_channel=$(notifications_generate_channel)
        echo "$ntfy_channel" > "$ntfy_channel_file"
        ui_print_success "Generated ntfy channel: $ntfy_channel"
        ui_print_info "Saved to: $ntfy_channel_file"
    fi

    # Create ntfy config inside the container
    if [[ -n "$container_name" ]]; then
        ui_print_info "Setting up ntfy configuration in container..."
        docker exec "$container_name" sh -c "
            mkdir -p /home/vscode/.config/claudetainer
            cat > /home/vscode/.config/claudetainer/ntfy.yaml << 'EOF'
ntfy_topic: $ntfy_channel
ntfy_server: https://ntfy.sh
EOF
            chown -R vscode:vscode /home/vscode/.config/claudetainer
        " 2> /dev/null && ui_print_success "Created ntfy config in container" || ui_print_warning "Could not create ntfy config in container"

        ui_print_info "Notification setup complete!"
        echo "  • Channel: $ntfy_channel"
        echo "  • Subscribe at: https://ntfy.sh/$ntfy_channel"
        echo "  • Or use ntfy app with topic: $ntfy_channel"
    fi
}

# Check notification setup status
notifications_check_setup() {
    local container_name="$1"
    local ntfy_channel_file=$(config_get_ntfy_channel_file)
    local issues_found=0

    # Check host notification channel file
    if [[ -f "$ntfy_channel_file" ]]; then
        local ntfy_channel=$(cat "$ntfy_channel_file" 2> /dev/null | tr -d '\n\r ')
        if [[ -n "$ntfy_channel" ]]; then
            ui_print_success "Notification channel configured: $ntfy_channel"
            echo "  • Subscribe at: https://ntfy.sh/$ntfy_channel"
        else
            ui_print_warning "Notification channel file is empty"
            ((issues_found++))
        fi
    else
        ui_print_info "No notification channel configured yet"
        echo "  • Will be created automatically on next 'claudetainer up'"
    fi

    # Check container notification config
    if [[ -n "$container_name" ]]; then
        local container_ntfy_check=$(docker_exec_in_container "$container_name" "cat /home/vscode/.config/claudetainer/ntfy.yaml 2>/dev/null")
        if [[ -n "$container_ntfy_check" ]]; then
            ui_print_success "Notification config found in container"

            # Parse and validate the config
            local container_topic=$(docker_exec_in_container "$container_name" "grep 'ntfy_topic:' /home/vscode/.config/claudetainer/ntfy.yaml 2>/dev/null | cut -d: -f2 | xargs")
            local container_server=$(docker_exec_in_container "$container_name" "grep 'ntfy_server:' /home/vscode/.config/claudetainer/ntfy.yaml 2>/dev/null | cut -d: -f2- | xargs")

            if [[ -n "$container_topic" ]]; then
                ui_print_success "Container notification topic: $container_topic"

                # Check if host and container topics match
                if [[ -f "$ntfy_channel_file" ]]; then
                    local host_channel=$(cat "$ntfy_channel_file" 2> /dev/null | tr -d '\n\r ')
                    if [[ "$host_channel" = "$container_topic" ]]; then
                        ui_print_success "Host and container notification channels match"
                    else
                        ui_print_warning "Host ($host_channel) and container ($container_topic) channels differ"
                        echo "  • This may cause notification confusion"
                        ((issues_found++))
                    fi
                fi
            else
                ui_print_warning "No notification topic found in container config"
                ((issues_found++))
            fi

            if [[ -n "$container_server" ]]; then
                ui_print_success "Container notification server: $container_server"
            else
                ui_print_warning "No notification server found in container config"
                ((issues_found++))
            fi

            # Test if yq is available in container (needed by notifier.sh)
            local yq_check=$(docker_exec_in_container "$container_name" "command -v yq >/dev/null 2>&1 && echo 'found'")
            if [[ "$yq_check" = "found" ]]; then
                ui_print_success "yq is available in container (required for notifications)"
            else
                ui_print_warning "yq not found in container - notifications may not work"
                echo "  • yq is required by notifier.sh to parse ntfy.yaml"
                ((issues_found++))
            fi

            # Test notification functionality
            local curl_check=$(docker_exec_in_container "$container_name" "command -v curl >/dev/null 2>&1 && echo 'found'")
            if [[ "$curl_check" = "found" ]]; then
                ui_print_success "curl is available in container (required for notifications)"
            else
                ui_print_warning "curl not found in container - notifications will not work"
                echo "  • curl is required by notifier.sh to send notifications"
                ((issues_found++))
            fi
        else
            ui_print_warning "No notification config found in container"
            echo "  • Config should be at: /home/vscode/.config/claudetainer/ntfy.yaml"
            echo "  • Run 'claudetainer up' to recreate container with notifications"
        fi
    else
        ui_print_info "No running container - cannot check container notification config"
    fi

    return $issues_found
}
