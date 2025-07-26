#!/bin/bash
# Zellij Debug Script for Claudetainer
# Run this inside your devcontainer to diagnose Zellij startup issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check function with detailed output
check_with_details() {
    local description="$1"
    local command="$2"
    local success_msg="$3"
    local failure_msg="$4"

    echo -n "Checking $description... "
    if eval "$command" >/dev/null 2>&1; then
        log_success "$success_msg"
        return 0
    else
        log_error "$failure_msg"
        return 1
    fi
}

# Main debug function
main() {
    log_header "🔍 Zellij Debug Script for Claudetainer"
    echo "This script will help diagnose why Zellij isn't starting in your devcontainer."
    echo "Run this inside your devcontainer terminal."
    echo

    # 1. Environment Information
    log_header "📋 Environment Information"
    echo -e "Date: $(date)"
    echo -e "User: $(whoami)"
    echo -e "Home: $HOME"
    echo -e "Shell: $SHELL"
    echo -e "PWD: $(pwd)"
    echo -e "Container ID: $(hostname)"

    # Check if we're in SSH session
    if [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" ]]; then
        log_success "SSH connection detected"
        echo -e "SSH_CONNECTION: ${SSH_CONNECTION:-not set}"
        echo -e "SSH_CLIENT: ${SSH_CLIENT:-not set}"
    else
        log_warning "No SSH connection detected"
    fi

    # Check for VS Code connection
    if [[ -n "${VSCODE_IPC_HOOK_CLI:-}" ]]; then
        log_info "VS Code remote connection detected"
        echo -e "VSCODE_IPC_HOOK_CLI: $VSCODE_IPC_HOOK_CLI"
    fi

    # 2. Zellij Installation Check
    log_header "🔧 Zellij Installation"
    if command -v zellij >/dev/null 2>&1; then
        log_success "Zellij binary found at: $(which zellij)"
        echo -e "Version: $(zellij --version)"

        # Check if it's executable
        if [[ -x "$(which zellij)" ]]; then
            log_success "Zellij binary is executable"
        else
            log_error "Zellij binary is not executable"
        fi
    else
        log_error "Zellij binary not found in PATH"
        echo -e "PATH: $PATH"
        return 1
    fi

    # 3. Configuration Check
    log_header "⚙️  Zellij Configuration"

    # Check config directory
    if [[ -d "$HOME/.config/zellij" ]]; then
        log_success "Zellij config directory exists: $HOME/.config/zellij"

        # List config contents
        echo -e "Config directory contents:"
        ls -la "$HOME/.config/zellij/"

        # Check main config
        if [[ -f "$HOME/.config/zellij/config.kdl" ]]; then
            log_success "Main config file exists"
            echo -e "Config file size: $(du -h "$HOME/.config/zellij/config.kdl" | cut -f1)"
        else
            log_warning "Main config file missing"
        fi

        # Check layouts directory
        if [[ -d "$HOME/.config/zellij/layouts" ]]; then
            log_success "Layouts directory exists"
            echo -e "Available layouts:"
            ls -la "$HOME/.config/zellij/layouts/"
        else
            log_error "Layouts directory missing"
        fi

    else
        log_error "Zellij config directory missing: $HOME/.config/zellij"
    fi

    # 4. Layout Validation
    log_header "📐 Layout File Validation"

    local default_layout="${ZELLIJ_LAYOUT:-tablet}"
    echo -e "Default layout: $default_layout"

    local layout_file="$HOME/.config/zellij/layouts/${default_layout}.kdl"
    if [[ -f "$layout_file" ]]; then
        log_success "Layout file exists: $layout_file"
        echo -e "Layout file size: $(du -h "$layout_file" | cut -f1)"

        # Validate layout syntax
        echo -n "Validating layout syntax... "
        if zellij --layout "$layout_file" setup --check >/dev/null 2>&1; then
            log_success "Layout syntax is valid"
        else
            log_error "Layout syntax validation failed"
            echo "Running syntax check with detailed output:"
            zellij --layout "$layout_file" setup --check 2>&1 || true
        fi
    else
        log_error "Layout file missing: $layout_file"

        # Check for other common layouts
        echo "Looking for alternative layouts:"
        for layout in tablet phone claude-dev claude-compact; do
            alt_file="$HOME/.config/zellij/layouts/${layout}.kdl"
            if [[ -f "$alt_file" ]]; then
                log_info "Found alternative: $alt_file"
            fi
        done
    fi

    # 5. Bashrc Integration Check
    log_header "🐚 Bashrc Integration"

    if [[ -f "$HOME/.bashrc" ]]; then
        log_success "Bashrc exists"

        # Check for claudetainer integration
        if grep -q "claudetainer" "$HOME/.bashrc"; then
            log_success "Claudetainer integration found in bashrc"
            echo "Claudetainer-related lines:"
            grep -n "claudetainer\|bashrc-multiplexer\|zellij" "$HOME/.bashrc" || true
        else
            log_warning "No claudetainer integration found in bashrc"
        fi

        # Check for multiplexer script
        if grep -q "bashrc-multiplexer.sh" "$HOME/.bashrc"; then
            log_success "Multiplexer auto-start script referenced"

            # Check if the script exists
            local script_path="$HOME/.config/claudetainer/scripts/bashrc-multiplexer.sh"
            if [[ -f "$script_path" ]]; then
                log_success "Multiplexer script exists: $script_path"
                echo -e "Script size: $(du -h "$script_path" | cut -f1)"

                # Check script syntax
                echo -n "Validating script syntax... "
                if bash -n "$script_path"; then
                    log_success "Script syntax is valid"
                else
                    log_error "Script syntax validation failed"
                fi
            else
                log_error "Multiplexer script missing: $script_path"
            fi
        else
            log_warning "No multiplexer auto-start script found in bashrc"
        fi
    else
        log_error "Bashrc file missing: $HOME/.bashrc"
    fi

    # 6. Environment Variables
    log_header "🌍 Environment Variables"

    echo "Zellij-related environment variables:"
    echo -e "ZELLIJ: ${ZELLIJ:-not set}"
    echo -e "ZELLIJ_LAYOUT: ${ZELLIJ_LAYOUT:-not set}"
    echo -e "ZELLIJ_SESSION_NAME: ${ZELLIJ_SESSION_NAME:-not set}"

    # Check for conflicting terminal multiplexers
    echo
    echo "Other multiplexer checks:"
    echo -e "TMUX: ${TMUX:-not set}"
    echo -e "STY (screen): ${STY:-not set}"

    # 7. Terminal Environment
    log_header "💻 Terminal Environment"

    echo -e "TERM: ${TERM:-not set}"
    echo -e "Terminal size: $(tput cols)x$(tput lines) (if supported)"

    # Check if we have a TTY
    if [[ -t 0 ]]; then
        log_success "Interactive terminal detected (stdin is a TTY)"
    else
        log_warning "Non-interactive terminal (stdin is not a TTY)"
    fi

    if [[ -t 1 ]]; then
        log_success "Output to terminal (stdout is a TTY)"
    else
        log_warning "Output redirected (stdout is not a TTY)"
    fi

    # 8. Process Check
    log_header "🔄 Process Information"

    echo "Current running zellij processes:"
    pgrep -fl zellij || echo "No zellij processes found"

    echo
    echo "Current shell process tree:"
    pstree -p $$ 2>/dev/null || ps -ef | grep -E "($$|bash|zellij)" || true

    # 9. Manual Zellij Test
    log_header "🧪 Manual Zellij Test"

    echo "Testing basic zellij functionality..."

    # Test zellij help
    echo -n "Testing 'zellij --help'... "
    if zellij --help >/dev/null 2>&1; then
        log_success "Help command works"
    else
        log_error "Help command failed"
    fi

    # Test zellij setup
    echo -n "Testing 'zellij setup --check'... "
    if zellij setup --check >/dev/null 2>&1; then
        log_success "Setup check passed"
    else
        log_error "Setup check failed"
        echo "Setup check output:"
        zellij setup --check 2>&1 || true
    fi

    # 10. Troubleshooting Suggestions
    log_header "💡 Troubleshooting Suggestions"

    echo "Based on the checks above, here are some things to try:"
    echo
    echo "1. Manual start test:"
    echo "   zellij --version"
    echo "   zellij --session test-session"
    echo
    echo "2. Check specific layout:"
    echo "   zellij --layout tablet --session test-tablet"
    echo "   zellij --layout phone --session test-phone"
    echo
    echo "3. Reset zellij configuration:"
    echo "   mv ~/.config/zellij ~/.config/zellij.backup"
    echo "   # Then rebuild your container"
    echo
    echo "4. Test without auto-start:"
    echo "   # Comment out the zellij lines in ~/.bashrc temporarily"
    echo "   # Then start a new shell and try manual zellij start"
    echo
    echo "5. Check container logs:"
    echo "   # From host: docker logs <container-name>"
    echo
    echo "6. Reinstall claudetainer feature:"
    echo "   # Rebuild your devcontainer with latest claudetainer version"

    # 11. System Resource Check
    log_header "📊 System Resources"

    echo "Available memory:"
    free -h 2>/dev/null || echo "free command not available"

    echo
    echo "Disk space in home directory:"
    du -sh "$HOME" 2>/dev/null || echo "du command failed"

    echo
    echo "Load average:"
    uptime 2>/dev/null || echo "uptime command not available"

    # Final summary
    log_header "📝 Summary"
    echo "Debug scan complete! Review the output above for any red ❌ items."
    echo "Focus on fixing those issues first, then try starting zellij manually."
    echo
    echo "If you're still having issues, please share this debug output when asking for help."
    echo
    log_info "You can also try: 'bash -x ~/.config/claudetainer/scripts/bashrc-multiplexer.sh' for detailed startup tracing"
    log_info "Quick test: 'source ~/.config/claudetainer/scripts/bashrc-multiplexer.sh' to test auto-start"
}

# Run the main function
main "$@"
