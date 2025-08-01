#!/bin/bash
# DevContainer Generator Library - DevContainer JSON generation

# Function to get current feature version from devcontainer-feature.json
devcontainer_get_feature_version() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local feature_json="$script_dir/../../src/claudetainer/devcontainer-feature.json"

    if [[ -f "$feature_json" ]]; then
        node -e "console.log(JSON.parse(require('fs').readFileSync('$feature_json', 'utf8')).version)" 2> /dev/null || echo "unknown"
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
    local lang_config=$(config_get_language_config "$lang")
    local image=$(echo "$lang_config" | grep "^image:" | cut -d: -f2-)

    cat << EOF
services:
  devcontainer:
    image: ${image}
    command: sleep infinity
    ports:
      - "${port}:${port}"                 # SSH
      - "$((60000 + port))-$((60000 + port + 10)):$((60000 + port))-$((60000 + port + 10))/udp"     # Mosh UDP range (direct mapping)
    volumes:
      - ../..:/workspaces:cached
      - ~/.claudetainer-credentials.json:/home/vscode/.claude/.credentials.json:cached
    labels:
      - "devcontainer.local_folder=${PWD}"
      - "devcontainer.language=${lang}"
      - "devcontainer.type=claudetainer"
      - "devcontainer.ssh_port=${port}"
    environment:
      - CLAUDETAINER=true
      - NODE_OPTIONS=--max-old-space-size=4096
EOF
}

# Generate devcontainer.json content for a language (compose-based)
devcontainer_generate_json() {
    local lang="$1"
    local port="$2"
    local multiplexer="${3:-zellij}"

    # Get current feature version
    local feature_version=$(devcontainer_get_feature_version)

    # Get language-specific configuration
    local lang_config=$(config_get_language_config "$lang")
    local name=$(echo "$lang_config" | grep "^name:" | cut -d: -f2-)
    local post_create_command=$(echo "$lang_config" | grep "^post_create:" | cut -d: -f2-)

    # Determine claudetainer feature configuration
    local claudetainer_config
    if [[ "$lang" == "base" ]]; then
        claudetainer_config='"includeBase": true, "include": "", "multiplexer": "'${multiplexer}'"'
    else
        claudetainer_config='"includeBase": true, "include": "'${lang}'", "multiplexer": "'${multiplexer}'"'
    fi

    # Get language-specific additional features
    local additional_features=$(config_get_language_features "$lang")

    cat << EOF
{
    "name": "${name}",
    "dockerComposeFile": "docker-compose.yml",
    "service": "devcontainer",
    "workspaceFolder": "/workspaces",
    "features": {
        "ghcr.io/devcontainers/features/node:1": {},
        "ghcr.io/anthropics/devcontainer-features/claude-code:1.0": {},
        "ghcr.io/smithclay/claudetainer/claudetainer:${feature_version}": {
            ${claudetainer_config}
        },$(if [[ -n "$additional_features" ]]; then echo -e "\n        $additional_features,"; fi)
        "ghcr.io/devcontainers-extra/features/mosh-apt-get:1": {},
        "ghcr.io/devcontainers/features/sshd:1": {
            "SSHD_PORT": ${port},
            "START_SSHD": "true",
            "NEW_PASSWORD": "vscode"
        }
    },
    "postCreateCommand": "${post_create_command}",
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

    # Generate docker-compose.yml and devcontainer.json with allocated port and multiplexer
    devcontainer_generate_compose "$language" "$port" "$multiplexer" > .devcontainer/claudetainer/docker-compose.yml
    devcontainer_generate_json "$language" "$port" "$multiplexer" > .devcontainer/claudetainer/devcontainer.json

    ui_print_success "Created .devcontainer/claudetainer/ config files for $language"
    ui_print_info "Generated: docker-compose.yml + devcontainer.json"
    ui_print_info "Allocated SSH port: $port"
    ui_print_info "Multiplexer: $multiplexer"

    return 0
}
