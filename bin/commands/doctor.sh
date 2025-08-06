#!/bin/bash
# Doctor Command - Comprehensive health check and debugging

# Check prerequisites and show installation guidance
cmd_check_prerequisites() {
    local missing_deps=()
    local all_good=true
    local verbose="${1:-false}"

    if [[ "$verbose" == "true" ]]; then
        ui_print_info "Checking prerequisites..."
    fi

    # Check Docker
    if ui_command_exists docker; then
        if docker info > /dev/null 2>&1; then
            if [[ "$verbose" == "true" ]]; then
                ui_print_success "Docker is installed and running"
            fi
        else
            ui_print_warning "Docker is installed but not running"
            echo "  → Start Docker Desktop or run: sudo systemctl start docker"
            all_good=false
        fi
    else
        ui_print_error "Docker is not installed"
        missing_deps+=("docker")
        all_good=false
    fi

    # Check Node.js
    if ui_command_exists node; then
        if [[ "$verbose" == "true" ]]; then
            local node_version=$(node --version)
            ui_print_success "Node.js is installed ($node_version)"
        fi
    else
        ui_print_error "Node.js is not installed"
        missing_deps+=("node")
        all_good=false
    fi

    # Check npm (comes with Node.js)
    if ui_command_exists npm; then
        if [[ "$verbose" == "true" ]]; then
            local npm_version=$(npm --version)
            ui_print_success "npm is installed ($npm_version)"
        fi
    else
        if ui_command_exists node; then
            ui_print_warning "Node.js found but npm missing (unusual)"
        fi
    fi

    # Check git
    if ui_command_exists git; then
        if [[ "$verbose" == "true" ]]; then
            local git_version=$(git --version | cut -d' ' -f3)
            ui_print_success "Git is installed ($git_version)"
        fi
    else
        ui_print_warning "Git is not installed (needed for GitHub presets)"
        missing_deps+=("git")
    fi

    # Check Tailscale CLI (optional but recommended for dashboard)
    local tailscale_cmd=""
    if ui_command_exists tailscale; then
        tailscale_cmd="tailscale"
    elif [[ -x "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]]; then
        tailscale_cmd="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
    fi

    if [[ -n "$tailscale_cmd" ]]; then
        if $tailscale_cmd status > /dev/null 2>&1; then
            if [[ "$verbose" == "true" ]]; then
                local tailscale_version=$($tailscale_cmd version | head -1 | cut -d' ' -f1)
                local install_method=""
                if [[ "$tailscale_cmd" == *"Applications"* ]]; then
                    install_method=" (Mac App Store)"
                fi
                ui_print_success "Tailscale is installed and connected ($tailscale_version$install_method)"
            fi
        else
            ui_print_warning "Tailscale is installed but not connected"
            echo "  → Run: $tailscale_cmd up"
        fi
    else
        ui_print_warning "Tailscale CLI not installed (optional, improves dashboard experience)"
        echo "  → Dashboard will use localhost instead of MagicDNS hostname"
        echo "  → Install via Homebrew, direct download, or Mac App Store"
    fi

    # Show installation guidance if needed
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo
        ui_print_info "Installation guidance:"

        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                docker)
                    echo "  ${WRENCH} Docker:"
                    echo "    • macOS/Windows: Download Docker Desktop from https://docker.com"
                    echo "    • Ubuntu/Debian: curl -fsSL https://get.docker.com | sh"
                    echo "    • With Homebrew: brew install --cask docker"
                    ;;
                node)
                    echo "  ${WRENCH} Node.js:"
                    echo "    • Download from https://nodejs.org (LTS recommended)"
                    echo "    • With Homebrew: brew install node"
                    echo "    • With package manager: sudo apt install nodejs npm"
                    ;;
                git)
                    echo "  ${WRENCH} Git:"
                    echo "    • Download from https://git-scm.com"
                    echo "    • With Homebrew: brew install git"
                    echo "    • With package manager: sudo apt install git"
                    ;;
                tailscale)
                    echo "  ${WRENCH} Tailscale (optional):"
                    echo "    • Download from https://tailscale.com/download"
                    echo "    • With Homebrew: brew install tailscale"
                    echo "    • After install: sudo tailscale up"
                    echo "    • Improves dashboard with MagicDNS hostnames"
                    ;;
            esac
            echo
        done

        ui_print_info "After installing dependencies, run 'claudetainer prereqs' to verify"
        return 1
    fi

    return 0
}

# Doctor command for debugging and health checks
cmd_doctor() {
    local issues_found=0

    ui_print_info "Running claudetainer doctor..."
    echo "======================================="
    echo

    # 0. Show version information
    ui_print_info "0. Version information..."
    ui_print_success "Claudetainer CLI: $VERSION"

    # Check .devcontainer for claudetainer feature version
    if [[ -f ".devcontainer/claudetainer/devcontainer.json" ]]; then
        local feature_version=""
        if ui_command_exists node; then
            # Extract claudetainer feature version from devcontainer.json
            feature_version=$(node -e "
				try {
					const config = JSON.parse(require('fs').readFileSync('.devcontainer/claudetainer/devcontainer.json', 'utf8'));
					const features = config.features || {};
					
					// Check different possible paths for claudetainer feature
					if (features['ghcr.io/smithclay/claudetainer/claudetainer']) {
						console.log('ghcr.io/smithclay/claudetainer/claudetainer');
					} else if (features['./claudetainer']) {
						console.log('local development');
					} else if (features['claudetainer']) {
						console.log('claudetainer (local)');
					} else {
						// Check if any feature contains 'claudetainer' in the key
						for (const [key, value] of Object.entries(features)) {
							if (key.includes('claudetainer')) {
								console.log(key);
								break;
							}
						}
					}
				} catch (e) {
					// Silently ignore errors
				}
			" 2> /dev/null)
        fi

        if [[ -n "$feature_version" ]]; then
            ui_print_success "DevContainer feature: $feature_version"
        else
            ui_print_info "DevContainer: Found (no claudetainer feature detected)"
        fi
    else
        ui_print_info "DevContainer: Not configured"
    fi
    echo

    # 1. Check prerequisites
    ui_print_info "1. Checking prerequisites..."
    if cmd_check_prerequisites > /dev/null 2>&1; then
        ui_print_success "All prerequisites satisfied"
    else
        ui_print_warning "Some prerequisites missing - run 'claudetainer prereqs' for details"
        ((issues_found++))
    fi
    echo

    # 2. Check current directory setup
    ui_print_info "2. Checking current directory setup..."

    # Check if in a project directory
    local detected_lang=$(validation_detect_language)
    if [[ -n "$detected_lang" ]]; then
        ui_print_success "Project language detected: $detected_lang"
    else
        ui_print_warning "No supported project files found in current directory"
        echo "  • Looking for: package.json, requirements.txt, pyproject.toml, Cargo.toml, go.mod, *.sh files"
    fi

    # Check for .devcontainer/claudetainer structure
    if [[ -d ".devcontainer/claudetainer" ]]; then
        ui_print_success ".devcontainer/claudetainer directory exists"

        # Validate devcontainer.json
        if [[ -f ".devcontainer/claudetainer/devcontainer.json" ]]; then
            ui_print_success "devcontainer.json found"

            # Check if it's a claudetainer devcontainer
            if grep -q "claudetainer" ".devcontainer/claudetainer/devcontainer.json" 2> /dev/null; then
                ui_print_success "claudetainer feature detected in devcontainer.json"
            else
                ui_print_warning "devcontainer.json exists but doesn't use claudetainer feature"
                echo "  • Run 'claudetainer init' to create a claudetainer devcontainer"
            fi

            # Validate JSON syntax
            if ui_command_exists node; then
                if node -e "JSON.parse(require('fs').readFileSync('.devcontainer/claudetainer/devcontainer.json', 'utf8'))" 2> /dev/null; then
                    ui_print_success "devcontainer.json is valid JSON"
                else
                    ui_print_error "devcontainer.json has invalid JSON syntax"
                    ((issues_found++))
                fi
            fi
        else
            ui_print_warning "devcontainer.json not found"
            echo "  • Run 'claudetainer init' to create one"
        fi
    else
        ui_print_warning "No .devcontainer/claudetainer directory found"
        echo "  • Run 'claudetainer init' to create one"
    fi
    echo

    # 3. Check Docker status
    ui_print_info "3. Checking Docker status..."
    if ui_command_exists docker; then
        if docker info > /dev/null 2>&1; then
            ui_print_success "Docker is running"

            # Check Docker memory allocation for sub-agent workloads (skip in CI)
            if [[ -z "${CI:-}" && -z "${GITHUB_ACTIONS:-}" && -z "${GITLAB_CI:-}" && -z "${JENKINS_URL:-}" && -z "${BUILDKITE:-}" && -z "${CIRCLECI:-}" && -z "${TRAVIS:-}" ]]; then
                if ! check_docker_memory_allocation "no-prompt"; then
                    ((issues_found++))
                fi
            else
                ui_print_info "Skipping Docker memory check in CI environment"
            fi

            # Check for existing containers
            local containers=$(docker_find_project_containers)
            if [[ -n "$containers" ]]; then
                ui_print_success "Found existing devcontainer(s): $containers"

                # Check if running
                local running=$(docker_find_running_project_containers)
                if [[ -n "$running" ]]; then
                    ui_print_success "Container is running: $running"
                else
                    ui_print_warning "Container exists but is not running"
                    echo "  • Run 'claudetainer up' to start it"
                fi
            else
                ui_print_info "No existing devcontainer found for this directory"
            fi
        else
            ui_print_error "Docker is installed but not running"
            echo "  • Start Docker Desktop or run: sudo systemctl start docker"
            ((issues_found++))
        fi
    else
        ui_print_error "Docker is not installed"
        ((issues_found++))
    fi
    echo

    # 4. Check port allocation status
    ui_print_info "4. Checking port allocation status..."
    pm_show_port_status
    echo

    # 5. Check SSH connectivity (if container should be running)
    ui_print_info "5. Checking SSH connectivity..."
    local ssh_port=$(pm_get_current_project_port)
    if nc -z localhost "$ssh_port" 2> /dev/null; then
        ui_print_success "SSH port $ssh_port is accessible"

        # Test actual SSH connection
        if timeout 5 ssh -p "$ssh_port" -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no vscode@localhost "echo 'SSH test successful'" 2> /dev/null; then
            ui_print_success "SSH connection test passed"
        else
            ui_print_warning "SSH port open but connection failed"
            echo "  • Try: ssh -p $ssh_port vscode@localhost (password: vscode)"
        fi
    else
        ui_print_info "SSH port $ssh_port not accessible (container likely not running)"
    fi
    echo

    # 6. Check claudetainer installation inside container (if running)
    ui_print_info "6. Checking claudetainer installation in container..."
    local container_name=$(docker_get_project_container_name)
    if [[ -n "$container_name" ]]; then
        local claude_check=$(docker_exec_in_container "$container_name" "ls /home/vscode/.claude/ 2>/dev/null")
        if [[ -n "$claude_check" ]]; then
            ui_print_success "Claude Code configuration found in container"

            # Check for specific claudetainer files
            local commands_check=$(docker_exec_in_container "$container_name" "ls /home/vscode/.claude/commands/*.md 2>/dev/null | wc -l")
            if [[ "$commands_check" -gt 0 ]]; then
                ui_print_success "Claudetainer commands installed ($commands_check commands)"
            else
                ui_print_warning "No claudetainer commands found in container"
            fi

            local hooks_check=$(docker_exec_in_container "$container_name" "ls /home/vscode/.claude/hooks/*.sh 2>/dev/null | wc -l")
            if [[ "$hooks_check" -gt 0 ]]; then
                ui_print_success "Claudetainer hooks installed ($hooks_check hooks)"
            else
                ui_print_warning "No claudetainer hooks found in container"
            fi

            # Check configured multiplexer
            local multiplexer_check=""
            if docker_exec_in_container "$container_name" "command -v zellij >/dev/null 2>&1"; then
                multiplexer_check="zellij"
            elif docker_exec_in_container "$container_name" "command -v tmux >/dev/null 2>&1"; then
                multiplexer_check="tmux"
            else
                multiplexer_check="none"
            fi

            if [[ "$multiplexer_check" != "none" ]]; then
                ui_print_success "Multiplexer configured: $multiplexer_check"

                # Check if multiplexer is properly configured
                if [[ "$multiplexer_check" == "zellij" ]]; then
                    local zellij_layouts_check=$(docker_exec_in_container "$container_name" "ls /home/vscode/.config/zellij/layouts/*.kdl 2>/dev/null")
                    if [[ -n "$zellij_layouts_check" ]]; then
                        ui_print_success "Zellij layouts configured"
                        # Check for specific bundled layouts
                        local claude_dev_check=$(docker_exec_in_container "$container_name" "ls /home/vscode/.config/zellij/layouts/tablet.kdl 2>/dev/null")
                        local claude_compact_check=$(docker_exec_in_container "$container_name" "ls /home/vscode/.config/zellij/layouts/phone.kdl 2>/dev/null")
                        if [[ -n "$claude_dev_check" ]] && [[ -n "$claude_compact_check" ]]; then
                            ui_print_success "Bundled layouts available: tablet, phone"
                        else
                            ui_print_warning "Some bundled layouts missing - check installation"
                        fi
                    else
                        ui_print_warning "Zellij layouts not found - sessions may not work properly"
                    fi
                elif [[ "$multiplexer_check" == "tmux" ]]; then
                    local tmux_config_check=$(docker_exec_in_container "$container_name" "ls /home/vscode/.tmux.conf 2>/dev/null")
                    if [[ -n "$tmux_config_check" ]]; then
                        ui_print_success "tmux configuration found"
                    else
                        ui_print_warning "tmux configuration missing - sessions may not work properly"
                    fi
                fi

                # Check if auto-start is configured
                local bashrc_multiplexer_check=$(docker_exec_in_container "$container_name" "grep -q 'bashrc-multiplexer.sh' /home/vscode/.bashrc 2>/dev/null && echo 'found'")
                if [[ "$bashrc_multiplexer_check" = "found" ]]; then
                    ui_print_success "Multiplexer auto-start configured"
                else
                    ui_print_warning "Multiplexer auto-start not configured"
                fi
            else
                ui_print_info "No multiplexer configured (using simple bash environment)"
            fi
        else
            ui_print_warning "Claude Code configuration not found in container"
            echo "  • Container may need to be rebuilt: docker system prune && claudetainer up"
        fi
    else
        ui_print_info "No running container found for this directory"
    fi
    echo

    # 7. Check notification setup
    ui_print_info "7. Checking notification setup..."
    local notification_issues=0
    if ! notifications_check_setup "$container_name"; then
        notification_issues=$?
    fi
    issues_found=$((issues_found + notification_issues))
    echo

    # 8. Check for common issues
    ui_print_info "8. Checking for common issues..."

    # Check credentials file
    local credentials_file=$(config_get_credentials_file)
    if [[ -f "$credentials_file" ]]; then
        ui_print_success "Credentials file exists: ~/.claudetainer-credentials.json"
    else
        ui_print_warning "Credentials file missing: ~/.claudetainer-credentials.json"
        echo "  • Will be created automatically on next 'claudetainer init'"
    fi

    # Check for port conflicts
    local port_check=$(lsof -i :"$ssh_port" 2> /dev/null | wc -l)
    if [[ "$port_check" -gt 0 ]]; then
        ui_print_success "Port $ssh_port is in use (likely by claudetainer)"
    else
        ui_print_info "Port $ssh_port is available"
    fi

    # Check disk space
    local disk_usage=$(df . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ "$disk_usage" -lt 90 ]]; then
        ui_print_success "Sufficient disk space available (${disk_usage}% used)"
    else
        ui_print_warning "Disk space is low (${disk_usage}% used)"
        echo "  • Consider running: docker system prune -a"
        ((issues_found++))
    fi
    echo

    # Summary
    echo "======================================="
    if [[ $issues_found -eq 0 ]]; then
        ui_print_success "Doctor check completed - no issues found!"
        echo "  Your claudetainer setup looks healthy ✨"
    else
        ui_print_warning "Doctor check completed with $issues_found issue(s) found"
        echo "  Review the warnings above and follow the suggested fixes"
        echo "  Run 'claudetainer doctor' again after making changes"
    fi

    return $issues_found
}
