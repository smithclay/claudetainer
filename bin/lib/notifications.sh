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
        
        # Get the language from container labels to determine the user
        local lang=$(docker inspect "$container_name" --format '{{ index .Config.Labels "devcontainer.language" }}' 2>/dev/null)
        local container_user=$(config_get_container_user "$lang")
        
        docker exec "$container_name" sh -c "
            mkdir -p /home/$container_user/.config/claudetainer
            cat > /home/$container_user/.config/claudetainer/ntfy.json << 'EOF'
{
  \"ntfy_topic\": \"$ntfy_channel\",
  \"ntfy_server\": \"https://ntfy.sh\"
}
EOF
            chown -R $container_user:$container_user /home/$container_user/.config/claudetainer
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
        # Get the language from container labels to determine the user
        local lang=$(docker inspect "$container_name" --format '{{ index .Config.Labels "devcontainer.language" }}' 2>/dev/null)
        local container_user=$(config_get_container_user "$lang")
        
        local container_ntfy_check=$(docker_exec_in_container "$container_name" "cat /home/$container_user/.config/claudetainer/ntfy.json 2>/dev/null")
        if [[ -n "$container_ntfy_check" ]]; then
            ui_print_success "Notification config found in container"

            # Parse and validate the config
            local container_topic=$(docker_exec_in_container "$container_name" "jq -r '.ntfy_topic // empty' /home/$container_user/.config/claudetainer/ntfy.json 2>/dev/null")
            local container_server=$(docker_exec_in_container "$container_name" "jq -r '.ntfy_server // empty' /home/$container_user/.config/claudetainer/ntfy.json 2>/dev/null")

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

            # Test if jq is available in container (needed by notifier.sh)
            local jq_check=$(docker_exec_in_container "$container_name" "command -v jq >/dev/null 2>&1 && echo 'found'")
            if [[ "$jq_check" = "found" ]]; then
                ui_print_success "jq is available in container (required for notifications)"
            else
                ui_print_warning "jq not found in container - notifications may not work"
                echo "  • jq is required by notifier.sh to parse ntfy.json"
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
            echo "  • Config should be at: /home/vscode/.config/claudetainer/ntfy.json"
            echo "  • Run 'claudetainer up' to recreate container with notifications"
        fi
    else
        ui_print_info "No running container - cannot check container notification config"
    fi

    return $issues_found
}
