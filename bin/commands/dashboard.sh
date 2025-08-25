#!/bin/bash
# Dashboard Command - Web dashboard for mobile SSH access

# Dashboard configuration
DASHBOARD_CONFIG_DIR="$HOME/.config/claudetainer"
DASHBOARD_PID_FILE="$DASHBOARD_CONFIG_DIR/dashboard.pid"
DASHBOARD_LOG_FILE="$DASHBOARD_CONFIG_DIR/dashboard.log"
DASHBOARD_SCRIPT="$SCRIPT_DIR/claudetainer-dashboard.js"

# Ensure dashboard config directory exists
dashboard_ensure_config_dir() {
    if [[ ! -d $DASHBOARD_CONFIG_DIR ]]; then
        mkdir -p "$DASHBOARD_CONFIG_DIR"
    fi
}

# Check if dashboard is running
dashboard_is_running() {
    if [[ -f $DASHBOARD_PID_FILE ]]; then
        local pid
        pid=$(cat "$DASHBOARD_PID_FILE" 2>/dev/null)
        if [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            # Clean up stale PID file
            rm -f "$DASHBOARD_PID_FILE" 2>/dev/null
            return 1
        fi
    fi
    return 1
}

# Get dashboard process ID
dashboard_get_pid() {
    if [[ -f $DASHBOARD_PID_FILE ]]; then
        cat "$DASHBOARD_PID_FILE" 2>/dev/null
    fi
}

# Start dashboard server
dashboard_start() {
    local port="${1:-8080}"
    local host="${2:-0.0.0.0}"

    # Check if already running
    if dashboard_is_running; then
        ui_print_warning "Dashboard is already running (PID: $(dashboard_get_pid))"
        cmd_dashboard_status
        return 0
    fi

    # Check prerequisites
    if ! ui_command_exists node; then
        ui_print_error "Node.js is required to run the dashboard"
        echo "Install Node.js and try again"
        return 1
    fi

    if ! ui_command_exists docker; then
        ui_print_error "Docker is required for container discovery"
        echo "Install Docker and try again"
        return 1
    fi

    if ! docker info >/dev/null 2>&1; then
        ui_print_error "Docker is not running"
        echo "Start Docker and try again"
        return 1
    fi

    # Ensure config directory exists
    dashboard_ensure_config_dir

    # Check if dashboard script exists
    if [[ ! -f $DASHBOARD_SCRIPT ]]; then
        ui_print_error "Dashboard script not found: $DASHBOARD_SCRIPT"
        return 1
    fi

    ui_print_info "Starting claudetainer dashboard..."

    # Start dashboard in background
    nohup node "$DASHBOARD_SCRIPT" --port "$port" --host "$host" >"$DASHBOARD_LOG_FILE" 2>&1 &
    local dashboard_pid=$!

    # Wait a moment to see if it started successfully
    sleep 2

    if kill -0 "$dashboard_pid" 2>/dev/null; then
        ui_print_success "Dashboard started successfully!"
        echo
        cmd_dashboard_status
    else
        ui_print_error "Failed to start dashboard"
        echo "Check logs with: claudetainer dashboard logs"
        return 1
    fi
}

# Stop dashboard server
dashboard_stop() {
    if ! dashboard_is_running; then
        ui_print_warning "Dashboard is not running"
        return 0
    fi

    local pid
    pid=$(dashboard_get_pid)
    ui_print_info "Stopping dashboard (PID: $pid)..."

    # Send SIGTERM for graceful shutdown
    if kill "$pid" 2>/dev/null; then
        # Wait for graceful shutdown
        local count=0
        while kill -0 "$pid" 2>/dev/null && [[ $count -lt 10 ]]; do
            sleep 1
            ((count++))
        done

        # Force kill if still running
        if kill -0 "$pid" 2>/dev/null; then
            ui_print_warning "Force killing dashboard process"
            kill -9 "$pid" 2>/dev/null
        fi

        # Clean up PID file
        rm -f "$DASHBOARD_PID_FILE" 2>/dev/null
        ui_print_success "Dashboard stopped"
    else
        ui_print_error "Failed to stop dashboard"
        return 1
    fi
}

# Show dashboard status
cmd_dashboard_status() {
    dashboard_ensure_config_dir

    echo "Dashboard Status:"
    echo "================"

    if dashboard_is_running; then
        local pid
        pid=$(dashboard_get_pid)
        local uptime=""

        # Get uptime if ps is available
        if ui_command_exists ps; then
            local start_time
            start_time=$(ps -o lstart= -p "$pid" 2>/dev/null | xargs)
            if [[ -n $start_time ]]; then
                uptime=" (started: $start_time)"
            fi
        fi

        ui_print_success "Status: Running ✅"
        echo "  PID: $pid$uptime"

        # Try to get URL from log file
        if [[ -f $DASHBOARD_LOG_FILE ]]; then
            local url
            url=$(grep "Dashboard server started on" "$DASHBOARD_LOG_FILE" | tail -1 | sed 's/.*http:/http:/')
            if [[ -n $url ]]; then
                echo "  URL: $url"
            fi
        fi

        echo "  Config: $DASHBOARD_CONFIG_DIR"
        echo "  Log: $DASHBOARD_LOG_FILE"
    else
        ui_print_error "Status: Not running ❌"
        echo "  Start with: claudetainer dashboard start"
    fi
    echo
}

# Show dashboard logs
cmd_dashboard_logs() {
    dashboard_ensure_config_dir

    if [[ ! -f $DASHBOARD_LOG_FILE ]]; then
        ui_print_warning "No log file found: $DASHBOARD_LOG_FILE"
        return 0
    fi

    local lines="${1:-20}"

    if [[ $lines == "follow" ]] || [[ $lines == "-f" ]]; then
        echo "Following dashboard logs (Ctrl+C to stop):"
        echo "=========================================="
        tail -f "$DASHBOARD_LOG_FILE"
    else
        echo "Dashboard logs (last $lines lines):"
        echo "==================================="
        tail -n "$lines" "$DASHBOARD_LOG_FILE"
    fi
}

# Get dashboard URL
cmd_dashboard_url() {
    if ! dashboard_is_running; then
        ui_print_error "Dashboard is not running"
        echo "Start with: claudetainer dashboard start"
        return 1
    fi

    if [[ -f $DASHBOARD_LOG_FILE ]]; then
        local url
        url=$(grep "Dashboard server started on" "$DASHBOARD_LOG_FILE" | tail -1 | sed 's/.*http:/http:/')
        if [[ -n $url ]]; then
            echo "$url"
            return 0
        fi
    fi

    # Fallback to default URL
    echo "http://localhost:8080"
}

# Main dashboard command dispatcher
cmd_dashboard() {
    local subcommand="${1:-status}"

    case "$subcommand" in
    start | up)
        shift
        local port="${1:-8080}"
        local host="${2:-0.0.0.0}"
        dashboard_start "$port" "$host"
        ;;
    stop | down)
        dashboard_stop
        ;;
    status)
        cmd_dashboard_status
        ;;
    logs)
        shift
        cmd_dashboard_logs "$@"
        ;;
    url)
        cmd_dashboard_url
        ;;
    restart)
        dashboard_stop
        sleep 1
        dashboard_start
        ;;
    --help | -h | help)
        cat <<'EOF'
Usage: claudetainer dashboard <command> [options]

Commands:
  start [port] [host]  Start dashboard server (default: port 8080, host 0.0.0.0)
  stop                 Stop dashboard server
  restart              Restart dashboard server
  status               Show dashboard status and URL
  logs [lines|-f]      Show dashboard logs (default: 20 lines, -f to follow)
  url                  Show dashboard URL

Examples:
  claudetainer dashboard start           # Start on default port 8080
  claudetainer dashboard start 9000     # Start on port 9000
  claudetainer dashboard status         # Check if running and get URL
  claudetainer dashboard logs -f        # Follow logs in real-time
  claudetainer dashboard stop           # Stop server

The dashboard provides a mobile-friendly web interface for connecting to
claudetainer containers via SSH, with deep links for Blink Shell.
EOF
        ;;
    *)
        ui_print_error "Unknown dashboard command: $subcommand"
        echo "Run 'claudetainer dashboard --help' for usage information"
        return 1
        ;;
    esac
}
