# CLI Reference

Complete command reference for the claudetainer CLI.

## Project Management
```bash
claudetainer init [language]    # Create devcontainer (auto-detects language)
claudetainer up                 # Start container (creates if missing)
claudetainer start              # Same as up
```

## Container Operations
```bash
claudetainer ssh                # Connect with multiplexer session
claudetainer list               # List running containers (aliases: ps, ls)
claudetainer rm                 # Remove containers for this project
claudetainer rm --config        # Also remove .devcontainer directory
claudetainer rm -f              # Force removal without confirmation
```

## Debugging and Health
```bash
claudetainer doctor             # Comprehensive health check
claudetainer prereqs            # Check prerequisites
```

## Manual Access
```bash
ssh -p 2223 vscode@localhost    # Direct SSH (password: vscode)
mosh --ssh="ssh -p 2223" --port=62223 vscode@localhost  # MOSH connection
```

## Command Details

### `claudetainer init [language]`
Creates a `.devcontainer` setup with claudetainer feature configured for the specified language.

**Language auto-detection:**
- Scans for `requirements.txt`, `pyproject.toml` → Python
- Scans for `package.json` → Node.js
- Scans for `go.mod` → Go
- Scans for `Cargo.toml` → Rust
- Scans for `*.sh` files → Shell

**Options:**
- `--multiplexer zellij|tmux|none` - Choose terminal multiplexer

### `claudetainer up`
Starts the devcontainer using the DevContainer CLI. Creates the container if it doesn't exist.

### `claudetainer ssh`
Connects to the running container via SSH and automatically starts the configured multiplexer session.

### `claudetainer list`
Shows running containers with:
- Container ID and name
- SSH port
- Status
- Local project folder

### `claudetainer doctor`
Comprehensive health check that validates:
- Docker is running
- DevContainer CLI is installed
- Container is running and accessible
- SSH connectivity
- Notification configuration

### `claudetainer rm`
Removes containers for the current project.

**Options:**
- `-f, --force` - Skip confirmation
- `--config` - Also remove `.devcontainer` directory
