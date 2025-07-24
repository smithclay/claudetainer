#!/bin/bash
# Remove Command - Container removal

# Remove claudetainer and associated containers
cmd_rm() {
	local force=false
	local remove_config=false
	local remove_all=false

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case $1 in
		-f | --force)
			force=true
			shift
			;;
		--config)
			remove_config=true
			shift
			;;
		--all)
			remove_all=true
			shift
			;;
		*)
			ui_print_error "Unknown option: $1"
			echo "Usage: claudetainer rm [-f|--force] [--config] [--all]"
			echo "  -f, --force    Force removal without confirmation"
			echo "  --config       Also remove .devcontainer directory"
			echo "  --all          Remove ALL claudetainer containers (not just current project)"
			return 1
			;;
		esac
	done

	# Remove containers using Docker operations library
	if [[ "$remove_all" = true ]]; then
		# Remove all claudetainer containers
		if [[ "$force" = true ]]; then
			docker_remove_all_claudetainer_containers "true"
		else
			if ! docker_remove_all_claudetainer_containers "false"; then
				return 0
			fi
		fi
	else
		# Remove only project containers
		if [[ "$force" = true ]]; then
			docker_remove_project_containers "true"
		else
			if ! docker_remove_project_containers "false"; then
				if [[ "$remove_config" = false ]]; then
					return 0
				fi
			fi
		fi
	fi

	# Handle .devcontainer directory removal
	if [[ "$remove_config" = true ]]; then
		if [[ -d ".devcontainer" ]]; then
			if [[ "$force" = false ]]; then
				read -p "Remove .devcontainer directory? [y/N]: " -n 1 -r
				echo
				if [[ $REPLY =~ ^[Yy]$ ]]; then
					rm -rf .devcontainer
					ui_print_success "Removed .devcontainer directory"
				else
					ui_print_info "Kept .devcontainer directory"
				fi
			else
				rm -rf .devcontainer
				ui_print_success "Removed .devcontainer directory"
			fi
		else
			ui_print_info "No .devcontainer directory found"
		fi
	fi
}
