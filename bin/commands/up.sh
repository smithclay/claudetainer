#!/bin/bash
# Up Command - Start devcontainer

# Start devcontainer
cmd_up() {
    local clean_build=false
    local verbose=false
    local language=""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                clean_build=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            --language)
                language="$2"
                shift 2
                ;;
            *)
                ui_print_error "Unknown option: $1"
                echo "Usage: claudetainer up [--clean] [--verbose] [--language <lang>]"
                echo "  --clean         Remove existing container and rebuild without cache"
                echo "  --verbose       Show detailed devcontainer CLI output"
                echo "  --language      Specify language for devcontainer creation (python, node, rust, go, shell)"
                return 1
                ;;
        esac
    done
    if [[ ! -f ".devcontainer/claudetainer/devcontainer.json" ]]; then
        ui_print_warning "No .devcontainer/claudetainer/devcontainer.json found"

        local lang_to_use=""

        # Use explicit language if provided
        if [[ -n "$language" ]]; then
            lang_to_use="$language"
            ui_print_info "Using specified language: $lang_to_use"
        else
            # Try to auto-detect language
            local detected_lang=$(validation_detect_language)
            if [[ -n "$detected_lang" ]]; then
                ui_print_info "Detected project language: $detected_lang"

                # In interactive mode, ask for confirmation
                if ui_is_interactive; then
                    read -p "Create devcontainer for $detected_lang? [Y/n]: " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Nn]$ ]]; then
                        ui_print_info "Aborted by user"
                        return 130 # Exit code 130 for user cancellation (Ctrl+C equivalent)
                    fi
                fi

                lang_to_use="$detected_lang"
            else
                # Failed to auto-detect language - default to base devcontainer
                ui_print_info "Could not auto-detect project language, creating base devcontainer"
                lang_to_use="base"
            fi
        fi

        # Create devcontainer with determined language
        if cmd_init "$lang_to_use"; then
            ui_print_success "Created devcontainer, now starting..."
        else
            local init_exit_code=$?
            ui_print_error "Failed to create devcontainer (exit code: $init_exit_code)"
            return $init_exit_code
        fi
    fi

    # Check if Node.js is available (needed for npx)
    if ! ui_command_exists node; then
        ui_print_error "Node.js not found"
        echo "Node.js is required to run devcontainer CLI via npx"
        echo "Install with: brew install node  # or visit https://nodejs.org"
        return 127 # Exit code 127 for "command not found"
    fi

    # Check if npm is available (needed for npx)
    if ! ui_command_exists npm; then
        ui_print_error "npm not found"
        echo "npm is required to run devcontainer CLI via npx"
        echo "npm usually comes with Node.js installation"
        return 127 # Exit code 127 for "command not found"
    fi

    # Check if container already exists for this directory
    local existing_containers=$(docker_find_project_containers)
    if [[ -n "$existing_containers" ]]; then
        if [[ "$clean_build" == "true" ]]; then
            ui_print_info "Clean build requested - removing existing container(s): $existing_containers"
            for container in $existing_containers; do
                ui_print_info "Removing container: $container"
                docker rm -f "$container" 2> /dev/null || true
            done
        else
            ui_print_error "A devcontainer already exists for this directory"
            echo "Existing container(s): $existing_containers"
            echo ""
            ui_print_info "To work with multiple instances of the same repository:"
            echo "  1. Use git worktree to create separate working directories:"
            echo "     git worktree add ../project-feature-branch feature-branch"
            echo "  2. Each worktree can have its own devcontainer"
            echo ""
            ui_print_info "To manage the existing container:"
            echo "  • Connect: claudetainer ssh"
            echo "  • Remove: claudetainer rm"
            echo "  • Status: claudetainer list"
            echo "  • Clean rebuild: claudetainer up --clean"
            return 2 # Exit code 2 for "already exists" condition
        fi
    fi

    # Build devcontainer with appropriate options
    ui_print_info "Starting devcontainer (may take a few minutes on first run, use --verbose to see container logs)..."
    echo ""

    # Run devcontainer command and capture exit code
    local exit_code=0

    if [[ "$verbose" == "true" ]]; then
        # Show all output when verbose
        if [[ "$clean_build" == "true" ]]; then
            npx @devcontainers/cli up --workspace-folder . --config .devcontainer/claudetainer/devcontainer.json --config .devcontainer/claudetainer/devcontainer.json --build-no-cache --remove-existing-container
        else
            npx @devcontainers/cli up --workspace-folder . --config .devcontainer/claudetainer/devcontainer.json
        fi
        exit_code=$?
    else
        # Non-verbose mode: suppress stdout only, preserve stderr
        if [[ "$clean_build" == "true" ]]; then
            npx @devcontainers/cli up --workspace-folder . --config .devcontainer/claudetainer/devcontainer.json --config .devcontainer/claudetainer/devcontainer.json --build-no-cache --remove-existing-container > /dev/null
        else
            npx @devcontainers/cli up --workspace-folder . --config .devcontainer/claudetainer/devcontainer.json > /dev/null
        fi
        exit_code=$?

        # If there was an error, immediately re-run with full output for diagnostics
        if [[ $exit_code -ne 0 ]]; then
            echo ""
            ui_print_error "❌ DevContainer failed (exit code: $exit_code)"
            echo ""
            ui_print_info "Re-running with full output to show error details:"
            echo ""

            if [[ "$clean_build" == "true" ]]; then
                npx @devcontainers/cli up --workspace-folder . --config .devcontainer/claudetainer/devcontainer.json --config .devcontainer/claudetainer/devcontainer.json --build-no-cache --remove-existing-container
            else
                npx @devcontainers/cli up --workspace-folder . --config .devcontainer/claudetainer/devcontainer.json
            fi

            echo ""
            ui_print_info "Diagnostic run completed. Original exit code: $exit_code"
        fi
    fi

    # Check if devcontainer command succeeded
    if [[ $exit_code -ne 0 ]]; then
        echo ""
        ui_print_error "❌ DevContainer failed to start (exit code: $exit_code)"
        echo ""
        ui_print_info "💡 Common solutions:"
        echo "  • Check that Docker is running: docker ps"
        echo "  • Verify devcontainer.json syntax is valid"
        echo "  • Try a clean rebuild: claudetainer up --clean"
        echo "  • Run with verbose output: claudetainer up --verbose"
        echo ""

        # Return the actual exit code from the devcontainer CLI
        return $exit_code
    fi

    # After container is up, set up notifications and credentials
    local container_name=$(docker_get_project_container_name)
    if [[ -n "$container_name" ]]; then
        # Wait a moment for container to be fully ready
        sleep 5

        # Set up notification channel and config
        notifications_setup_channel "$container_name"

        # Check credentials and set onboarding flag
        local credentials_file=$(config_get_credentials_file)
        if [[ -f "$credentials_file" ]]; then
            local file_content=$(cat "$credentials_file" 2> /dev/null)
            if [[ "$file_content" != "{}" ]] && [[ -n "$file_content" ]] && [[ "$file_content" != "" ]]; then
                ui_print_info "Setting Claude Code onboarding complete flag in container..."
                docker_exec_in_container "$container_name" "echo '{\"hasCompletedOnboarding\": true}' > /home/vscode/.claude.json" || ui_print_warning "Could not set onboarding flag in container"
            fi
        fi
    else
        ui_print_warning "Could not find container for post-setup configuration"
    fi

    echo
    ui_print_success "Container is ready!"
    ui_print_info "Next steps:"
    echo "  1. Run 'claudetainer ssh' to connect and start coding"
    echo "  2. Use 'claudetainer list' to see running containers"
    echo "  3. Run 'claudetainer doctor' if you encounter issues"
    echo
    local ssh_port=$(pm_get_current_project_port)
    local mosh_port=$((60000 + ssh_port))
    ui_print_info "Container details:"
    echo "  • SSH port: $ssh_port"
    echo "  • Direct SSH: ssh -p $ssh_port vscode@localhost (password: vscode)"
    echo "  • Mosh port range: $mosh_port-$((mosh_port + 10))"
    echo "  • Direct Mosh: mosh --ssh=\"ssh -p $ssh_port\" --port=$mosh_port vscode@localhost"
    echo "  • Workspace: /workspaces (mounted from current directory)"
}
