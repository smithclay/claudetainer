#!/bin/bash
# Init Command - Project initialization

# Initialize devcontainer for a language
cmd_init() {
	local language="${1:-}"
	local multiplexer="zellij"

	# Parse options
	shift
	while [[ $# -gt 0 ]]; do
		case $1 in
		--multiplexer)
			multiplexer="$2"
			shift 2
			;;
		--no-tmux)
			# Legacy option for backward compatibility
			multiplexer="none"
			shift
			;;
		*)
			# Unknown option, ignore
			shift
			;;
		esac
	done

	# Ensure credentials file exists before creating devcontainer
	notifications_ensure_credentials_file

	# Auto-detect language if not provided
	if [[ -z "$language" ]]; then
		language=$(validation_detect_language)
		if [[ -z "$language" ]]; then
			ui_print_error "Could not auto-detect project language"
			echo "Please specify a language: claudetainer init <language>"
			echo "Supported languages: python, node, rust, go"
			return 1
		fi
		ui_print_info "Auto-detected language: $language"
	fi

	# Validate language and multiplexer
	if ! validation_validate_language "$language"; then
		return 1
	fi

	if ! validation_validate_multiplexer "$multiplexer"; then
		return 1
	fi

	# Create devcontainer configuration
	if devcontainer_create_config "$language" "$multiplexer"; then
		ui_print_info "Next steps:"
		echo "  1. Run 'claudetainer up' to start the container"
		echo "  2. Run 'claudetainer ssh' to connect once it's running"
		return 0
	else
		return 1
	fi
}
