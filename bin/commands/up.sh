#!/bin/bash
# Up Command - Start devcontainer

# Start devcontainer
cmd_up() {
	if [[ ! -f ".devcontainer/devcontainer.json" ]]; then
		ui_print_warning "No .devcontainer/devcontainer.json found"

		# Try to auto-detect language
		local detected_lang=$(validation_detect_language)
		if [[ -n "$detected_lang" ]]; then
			ui_print_info "Detected project language: $detected_lang"
			read -p "Create devcontainer for $detected_lang? [Y/n]: " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Nn]$ ]]; then
				ui_print_info "Aborted"
				return 1
			fi

			# Create devcontainer
			if cmd_init "$detected_lang"; then
				ui_print_success "Created devcontainer, now starting..."
			else
				ui_print_error "Failed to create devcontainer"
				return 1
			fi
		else
			ui_print_error "Could not auto-detect project language"
			echo "Available languages: python, node, rust, go, shell"
			read -r -p "Enter language to create devcontainer for (or press Enter to abort): " lang
			if [[ -z "$lang" ]]; then
				ui_print_info "Aborted"
				return 1
			fi

			# Create devcontainer with specified language
			if cmd_init "$lang"; then
				ui_print_success "Created devcontainer, now starting..."
			else
				ui_print_error "Failed to create devcontainer"
				return 1
			fi
		fi
	fi

	# Check if Node.js is available (needed for npx)
	if ! ui_command_exists node; then
		ui_print_error "Node.js not found"
		echo "Node.js is required to run devcontainer CLI via npx"
		echo "Install with: brew install node  # or visit https://nodejs.org"
		return 1
	fi

	# Check if npm is available (needed for npx)
	if ! ui_command_exists npm; then
		ui_print_error "npm not found"
		echo "npm is required to run devcontainer CLI via npx"
		echo "npm usually comes with Node.js installation"
		return 1
	fi

	ui_print_info "Starting devcontainer using npx @devcontainers/cli..."
	npx @devcontainers/cli up --workspace-folder .

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
			local file_content=$(cat "$credentials_file" 2>/dev/null)
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
	ui_print_info "Inside the container, try these Claude Code features:"
	echo "  • Type 'claude' to interact with Claude directly"
	echo "  • Use slash commands like '/commit' and '/check'"
	echo "  • All your files are automatically linted and formatted"
	echo "  • Push notifications are configured and ready to use"
	echo
	local ssh_port=$(pm_get_current_project_port)
	ui_print_info "Container details:"
	echo "  • SSH port: $ssh_port"
	echo "  • Direct SSH: ssh -p $ssh_port vscode@localhost (password: vscode)"
	echo "  • Workspace: /workspaces (mounted from current directory)"
}
