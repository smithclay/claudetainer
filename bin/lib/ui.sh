#!/bin/bash
# UI Library - Color output and user interaction functions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Emojis for visual feedback
CHECKMARK="✅"
CROSS="❌"
ROCKET="🚀"
WRENCH="🔧"

# Print colored output functions
ui_print_error() {
	echo -e "${RED}${CROSS} Error: $1${NC}" >&2
}

ui_print_success() {
	echo -e "${GREEN}${CHECKMARK} $1${NC}"
}

ui_print_info() {
	echo -e "${BLUE}${ROCKET} $1${NC}"
}

ui_print_warning() {
	echo -e "${YELLOW}${WRENCH} $1${NC}"
}

# Check if a command exists
ui_command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Show help message
ui_show_help() {
	cat <<EOF
claudetainer CLI v${VERSION}
Easy and opinionated Claude Code in a dev container.

USAGE:
    claudetainer <COMMAND> [OPTIONS]

COMMANDS:
    prereqs           Check prerequisites and show installation guidance
    doctor            Comprehensive health check and debugging
    init <language>   Create .devcontainer folder with claudetainer feature
                     Supported languages: python, node, rust, go, shell
                     Will auto-detect if language not specified
                     Creates ~/.claudetainer-credentials.json if missing
                     Options: --multiplexer zellij|tmux|none (default: zellij)

    up, start        Start the devcontainer (uses npx @devcontainers/cli)
    ssh              SSH into running container with configured multiplexer session
    rm               Remove claudetainer containers and optionally config
    list, ps, ls     List running containers with names, ports, and status

    --help, -h       Show this help message
    --version, -v    Show version information

EXAMPLES:
    claudetainer prereqs         # Check if Docker, Node.js are installed
    claudetainer doctor          # Run comprehensive health check
    claudetainer init python     # Create Python devcontainer
    claudetainer init            # Auto-detect language and create devcontainer
    claudetainer up              # Start the devcontainer
    claudetainer start           # Same as up
    claudetainer ssh             # Connect to running container
    claudetainer rm              # Remove containers for this project
    claudetainer rm --config     # Remove containers and .devcontainer dir
    claudetainer rm -f           # Force remove without confirmation
    claudetainer list            # List running containers
    claudetainer ps              # Same as list
    claudetainer ls              # Same as list

For more information, visit: https://github.com/smithclay/claudetainer
EOF
}

# Show version
ui_show_version() {
	echo "claudetainer ${VERSION}"
}
