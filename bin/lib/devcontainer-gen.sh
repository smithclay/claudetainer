#!/bin/bash
# DevContainer Generator Library - DevContainer JSON generation

# Function to get current feature version from devcontainer-feature.json
devcontainer_get_feature_version() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local feature_json="$script_dir/../../src/claudetainer/devcontainer-feature.json"

    if [[ -f $feature_json ]]; then
        node -e "console.log(JSON.parse(require('fs').readFileSync('$feature_json', 'utf8')).version)" 2>/dev/null || echo "unknown"
    else
        echo "unknown" # fallback version
    fi
}

# Generate docker-compose.yml content for a language
devcontainer_generate_compose() {
    local lang="$1"
    local port="$2"
    local multiplexer="${3:-zellij}"

    # Get language-specific configuration
    local lang_config
    lang_config=$(config_get_language_config "$lang")
    local image
    image=$(echo "$lang_config" | grep "^image:" | cut -d: -f2-)

    # Get the correct default user for this language
    local default_user
    default_user=$(devcontainer_get_default_user "$lang")

    # Generate unique service name based on project path and port to avoid conflicts
    local project_hash
    project_hash=$(echo "$PWD" | shasum | head -c8)
    local service_name="devcontainer-${project_hash}-${port}"

    cat <<EOF
version: '3.8'
services:
  ${service_name}:
    image: ${image}
    command: sleep infinity
    ports:
      - "${port}:${port}"                 # SSH
      - "$((60000 + port))-$((60000 + port + 10)):$((60000 + port))-$((60000 + port + 10))/udp"     # Mosh UDP range (direct mapping)
    volumes:
      - ../..:/workspaces:cached
      - ~/.claudetainer-credentials.json:/home/${default_user}/.claude/.credentials.json:cached
      - ~/.config/claudetainer/ssh:/home/${default_user}/.claudetainer-ssh:ro
    labels:
      - "devcontainer.local_folder=${PWD}"
      - "devcontainer.language=${lang}"
      - "devcontainer.type=claudetainer"
      - "devcontainer.ssh_port=${port}"
    environment:
      - CLAUDETAINER=true
      - NODE_OPTIONS=--max-old-space-size=8192
EOF
}

# Get the default user for a language's base image
devcontainer_get_default_user() {
    local lang="$1"
    case "$lang" in
    node)
        echo "node" # javascript-node image has 'node' user
        ;;
    python | rust | go | shell | base | *)
        echo "vscode" # Other images use 'vscode' user
        ;;
    esac
}

# Generate devcontainer.json content for a language (compose-based)
devcontainer_generate_json() {
    local lang="$1"
    local port="$2"
    local multiplexer="${3:-zellij}"

    # Get current feature version
    local feature_version
    feature_version=$(devcontainer_get_feature_version)

    # Get language-specific configuration
    local lang_config
    lang_config=$(config_get_language_config "$lang")
    local name
    name=$(echo "$lang_config" | grep "^name:" | cut -d: -f2-)
    local post_create_command
    post_create_command=$(echo "$lang_config" | grep "^post_create:" | cut -d: -f2-)

    # Generate unique service name based on project path and port to avoid conflicts
    local project_hash
    project_hash=$(echo "$PWD" | shasum | head -c8)
    local service_name="devcontainer-${project_hash}-${port}"

    # Determine claudetainer feature configuration
    local claudetainer_config
    if [[ $lang == "base" ]]; then
        claudetainer_config='"includeBase": true, "include": "", "multiplexer": "'${multiplexer}'"'
    else
        claudetainer_config='"includeBase": true, "include": "'${lang}'", "multiplexer": "'${multiplexer}'"'
    fi

    # Get language-specific additional features
    local additional_features
    additional_features=$(config_get_language_features "$lang")

    # Get the correct default user for this language
    local default_user
    default_user=$(devcontainer_get_default_user "$lang")

    # Determine if we need the Node.js feature (exclude for node language since base image already has it)
    local node_feature=""
    if [[ $lang != "node" ]]; then
        node_feature='"ghcr.io/devcontainers/features/node:1": {},'
    fi

    cat <<EOF
{
    "name": "${name}",
    "dockerComposeFile": "docker-compose.yml",
    "service": "${service_name}",
    "workspaceFolder": "/workspaces",
    "features": {
        ${node_feature}
        "ghcr.io/anthropics/devcontainer-features/claude-code:1.0": {},
        "ghcr.io/smithclay/claudetainer/claudetainer:${feature_version}": {
            ${claudetainer_config}
        },$(if [[ -n $additional_features ]]; then echo -e "\n        $additional_features,"; fi)
        "ghcr.io/devcontainers-extra/features/mosh-apt-get:1": {},
        "ghcr.io/devcontainers/features/sshd:1": {
            "SSHD_PORT": ${port},
            "START_SSHD": "true",
            "USERNAME": "${default_user}",
            "NEW_PASSWORD": "${default_user}"
        }
    },
    "postCreateCommand": "${post_create_command} && /workspaces/.devcontainer/claudetainer/postinstall.sh",
    "postStartCommand": "/workspaces/.devcontainer/claudetainer/setup-ssh-keys.sh",
    "forwardPorts": [
        ${port}
    ],
    "customizations": {
        "vscode": {
            "extensions": []
        }
    }
}
EOF
}

# Generate postinstall.sh script content
devcontainer_generate_postinstall() {
    cat <<'EOF'
#!/bin/bash
# PostInstall Script for Claudetainer DevContainers
# This script runs after devcontainer creation to setup Claude Code environment

set -euo pipefail

# Print Claude Code version
print_claude_version() {
    echo "=== Claude Code Environment Setup ==="
    if command -v claude >/dev/null 2>&1; then
        echo "Claude Code version: $(claude --version 2>/dev/null || echo 'unknown')"
    else
        echo "Claude Code: not found in PATH"
    fi
    echo
}

# Create user setup (placeholder)
setup_user() {
    echo "=== User Setup ==="
    local username="${1:-vscode}"
    echo "Setting up user: $username"

    # TODO: Add user-specific setup here
    # - Configure shell preferences
    # - Setup dotfiles
    # - Configure Claude Code settings

    echo "User setup completed for: $username"
    echo
}

# Detect the appropriate user for SSH setup
detect_ssh_user() {
    # Try users in order of preference: passed parameter, existing users
    local preferred_user="${1:-}"

    # If a user was specified and exists, use it
    if [[ -n $preferred_user ]] && id "$preferred_user" >/dev/null 2>&1; then
        echo "$preferred_user"
        return 0
    fi

    # Try common devcontainer users in order
    for candidate_user in vscode node nodejs; do
        if id "$candidate_user" >/dev/null 2>&1; then
            echo "$candidate_user"
            return 0
        fi
    done

    # Fallback to current user
    echo "$(whoami)"
}

# Setup SSH access for claudetainer keys
setup_ssh_access() {
    echo "=== SSH Access Setup ==="
    local preferred_user="${1:-}"

    # Detect the actual user to use
    local username
    username=$(detect_ssh_user "$preferred_user")

    local ssh_dir="/home/$username/.ssh"
    local authorized_keys_file="$ssh_dir/authorized_keys"
    local claudetainer_ssh_dir="/home/$username/.claudetainer-ssh"

    echo "Setting up SSH access for detected user: $username"

    # Ensure SSH directory exists
    if [[ ! -d "$ssh_dir" ]]; then
        sudo mkdir -p "$ssh_dir"
        sudo chmod 700 "$ssh_dir"
        sudo chown "$username:$username" "$ssh_dir" 2>/dev/null || true
    fi

    # Setup authorized_keys with claudetainer public key
    if [[ -f "$claudetainer_ssh_dir/claudetainer_rsa.pub" ]]; then
        echo "Adding claudetainer public key to authorized_keys..."

        # Copy the public key to authorized_keys (create file in the process)
        sudo cp "$claudetainer_ssh_dir/claudetainer_rsa.pub" "$authorized_keys_file"
        sudo chmod 600 "$authorized_keys_file"
        sudo chown "$username:$username" "$authorized_keys_file" 2>/dev/null || true
        echo "SSH access configured for claudetainer key"
    else
        echo "Warning: Claudetainer public key not found at $claudetainer_ssh_dir/claudetainer_rsa.pub"
        echo "SSH access will fall back to password authentication"
        # Ensure authorized_keys exists even without keys
        sudo touch "$authorized_keys_file"
        sudo chmod 600 "$authorized_keys_file"
        sudo chown "$username:$username" "$authorized_keys_file" 2>/dev/null || true
    fi

    echo "SSH access setup completed for user: $username"
    echo
}

# Main postinstall function
main() {
    local preferred_user="${1:-}"

    echo "Starting Claudetainer post-installation setup..."
    echo "Preferred user: ${preferred_user:-auto-detect}"
    echo

    print_claude_version
    setup_ssh_access "$preferred_user"
    #setup_user "$username"

    echo "=== Claudetainer Setup Complete ==="
    echo "Environment is ready for Claude Code development"
}

# Run main function - will auto-detect appropriate user
main "$@"
EOF
}

# Generate SSH key setup script for postStartCommand
devcontainer_generate_ssh_setup() {
    cat <<'EOF'
#!/bin/bash
# SSH Key Setup Script - Runs on container start to copy SSH keys
# This ensures SSH keys are available even when containers are restarted

set -e

echo "=== SSH Key Setup ==="

# Find the appropriate user (try common devcontainer users)
target_user=""
for candidate_user in vscode node nodejs; do
    if id "$candidate_user" >/dev/null 2>&1; then
        target_user="$candidate_user"
        echo "Using detected user: $target_user"
        break
    fi
done

if [[ -z $target_user ]]; then
    echo "Warning: No suitable user found for SSH key setup"
    exit 0
fi

# Setup paths
ssh_dir="/home/$target_user/.ssh"
authorized_keys_file="$ssh_dir/authorized_keys"
claudetainer_ssh_dir="/home/$target_user/.claudetainer-ssh"

# Ensure SSH directory exists with correct permissions
sudo mkdir -p "$ssh_dir"
sudo chmod 700 "$ssh_dir"
sudo chown "$target_user:$target_user" "$ssh_dir" 2>/dev/null || true

# Copy SSH key if available
if [[ -f "$claudetainer_ssh_dir/claudetainer_rsa.pub" ]]; then
    echo "Copying claudetainer public key to authorized_keys..."

    # Copy SSH key to authorized_keys (create file in the process)
    sudo cp "$claudetainer_ssh_dir/claudetainer_rsa.pub" "$authorized_keys_file"
    sudo chmod 600 "$authorized_keys_file"
    sudo chown "$target_user:$target_user" "$authorized_keys_file" 2>/dev/null || true
    echo "✅ SSH key-based authentication configured for user: $target_user"
else
    echo "⚠️  No claudetainer SSH key found - password authentication will be required"
    # Ensure authorized_keys exists even without keys
    sudo touch "$authorized_keys_file"
    sudo chmod 600 "$authorized_keys_file"
    sudo chown "$target_user:$target_user" "$authorized_keys_file" 2>/dev/null || true
fi

echo "SSH key setup completed"
EOF
}

# Create devcontainer directory and JSON file
devcontainer_create_config() {
    local language="$1"
    local multiplexer="$2"

    # Check if claudetainer config already exists
    if [[ -f ".devcontainer/claudetainer/devcontainer.json" ]]; then
        ui_print_warning "Claudetainer devcontainer config already exists"
        read -p "Overwrite existing claudetainer config? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            ui_print_info "Aborted"
            return 1
        fi
        rm -rf .devcontainer/claudetainer
    fi

    # Create .devcontainer/claudetainer directory
    mkdir -p .devcontainer/claudetainer

    # Get or allocate port for this project
    local port
    if ! port=$(pm_get_project_port); then
        ui_print_error "Failed to allocate port for project"
        return 1
    fi

    # Generate docker-compose.yml, devcontainer.json, postinstall.sh, and SSH setup script with allocated port and multiplexer
    devcontainer_generate_compose "$language" "$port" "$multiplexer" >.devcontainer/claudetainer/docker-compose.yml
    devcontainer_generate_json "$language" "$port" "$multiplexer" >.devcontainer/claudetainer/devcontainer.json
    devcontainer_generate_postinstall >.devcontainer/claudetainer/postinstall.sh
    devcontainer_generate_ssh_setup >.devcontainer/claudetainer/setup-ssh-keys.sh
    chmod +x .devcontainer/claudetainer/postinstall.sh
    chmod +x .devcontainer/claudetainer/setup-ssh-keys.sh

    ui_print_success "Created .devcontainer/claudetainer/ config files for $language"
    ui_print_info "Generated: docker-compose.yml + devcontainer.json + postinstall.sh + setup-ssh-keys.sh"
    ui_print_info "Allocated SSH port: $port"
    ui_print_info "Multiplexer: $multiplexer"

    return 0
}
