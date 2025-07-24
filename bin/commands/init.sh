#!/bin/bash
# Init Command - Project initialization

# Initialize devcontainer for a language
cmd_init() {
    local language="${1:-}"
    local multiplexer="zellij"

    # Parse options (shift only if there are arguments)
    [[ $# -gt 0 ]] && shift
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

    # If no language specified, create base devcontainer
    if [[ -z "$language" ]]; then
        ui_print_info "Creating base devcontainer without language-specific presets"
        language="base"
    else
        # Validate language if specified
        if ! validation_validate_language "$language"; then
            return 1
        fi
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
