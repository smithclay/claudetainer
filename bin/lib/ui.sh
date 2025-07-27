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
    command -v "$1" > /dev/null 2>&1
}

# Check if we're in an interactive environment
ui_is_interactive() {
    # Check if stdin is a terminal and we have a controlling terminal
    [[ -t 0 ]] && [[ -t 1 ]] && [[ -z "${CI:-}" ]] && [[ -z "${GITHUB_ACTIONS:-}" ]] && [[ -z "${BUILDKITE:-}" ]] && [[ -z "${JENKINS_URL:-}" ]]
}

# Show help message
ui_show_help() {
    cat << EOF
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

    run, up, start   Start the devcontainer (uses npx @devcontainers/cli)
                     Options: --clean (remove existing container and rebuild without cache)
                              --verbose (show detailed devcontainer CLI output)
                              --language <lang> (specify language for devcontainer creation)
    ssh              SSH into running container with configured multiplexer session
    mosh             Connect via MOSH (mobile shell) for resilient remote sessions
    rm               Remove claudetainer containers and optionally config
                     Options: --all (remove all claudetainer containers)
                              --config (also remove .devcontainer directory)
                              -f, --force (skip confirmation prompts)
    list, ps, ls     List running containers with names, ports, and status
    dashboard        Manage web dashboard for mobile SSH access
                     Commands: start, stop, status, logs, url
                     The dashboard provides Blink Shell deep links

    --help, -h       Show this help message
    --version, -v    Show version information

EXAMPLES:
    claudetainer prereqs         # Check if Docker, Node.js are installed
    claudetainer doctor          # Run comprehensive health check
    claudetainer init python     # Create Python devcontainer
    claudetainer init            # Auto-detect language and create devcontainer
    claudetainer run             # Start the devcontainer (quiet by default)
    claudetainer run --clean     # Clean rebuild (remove existing container, no cache)
    claudetainer run --verbose   # Start with detailed output
    claudetainer run --language python  # Force create Python devcontainer
    claudetainer up              # Same as run (alias)
    claudetainer start           # Same as run (alias)
    claudetainer ssh             # Connect to running container
    claudetainer rm              # Remove containers for this project
    claudetainer rm --config     # Remove containers and .devcontainer dir
    claudetainer rm --all        # Remove ALL claudetainer containers
    claudetainer rm -f           # Force remove without confirmation
    claudetainer list            # List running containers
    claudetainer ps              # Same as list
    claudetainer ls              # Same as list
    claudetainer dashboard start # Start web dashboard for mobile access
    claudetainer dashboard status # Show dashboard URL and status

For more information, visit: https://github.com/smithclay/claudetainer
EOF
}

# Show version
ui_show_version() {
    echo "claudetainer ${VERSION}"
}
