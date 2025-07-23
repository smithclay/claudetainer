#!/bin/bash
# DevContainer Generator Library - DevContainer JSON generation

# Function to get current feature version from devcontainer-feature.json
devcontainer_get_feature_version() {
	local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	local feature_json="$script_dir/../../src/claudetainer/devcontainer-feature.json"

	if [[ -f "$feature_json" ]]; then
		node -e "console.log(JSON.parse(require('fs').readFileSync('$feature_json', 'utf8')).version)" 2>/dev/null || echo "unknown"
	else
		echo "unknown" # fallback version
	fi
}

# Generate devcontainer.json content for a language
devcontainer_generate_json() {
	local lang="$1"
	local port="$2"
	local multiplexer="${3:-zellij}"

	# Get current feature version
	local feature_version=$(devcontainer_get_feature_version)

	# Get language-specific configuration
	local lang_config=$(config_get_language_config "$lang")
	local name=$(echo "$lang_config" | grep "^name:" | cut -d: -f2-)
	local image=$(echo "$lang_config" | grep "^image:" | cut -d: -f2-)
	local post_create_command=$(echo "$lang_config" | grep "^post_create:" | cut -d: -f2-)

	cat <<EOF
{
    "name": "${name}",
    "image": "${image}",
    "features": {
        "ghcr.io/devcontainers/features/node:1": {},
        "ghcr.io/anthropics/devcontainer-features/claude-code:1.0": {},
        "ghcr.io/smithclay/claudetainer/claudetainer:${feature_version}": {
            "includeBase": true,
            "include": "${lang}",
            "multiplexer": "${multiplexer}"
        },
        "ghcr.io/devcontainers/features/sshd:1": {
            "SSHD_PORT": ${port},
            "START_SSHD": "true",
            "NEW_PASSWORD": "vscode"
        }
    },
    "postCreateCommand": "${post_create_command}",
    "mounts": [
        "source=\${localEnv:HOME}\${localEnv:USERPROFILE}/.claudetainer-credentials.json,target=/home/vscode/.claude/.credentials.json,type=bind,consistency=cached"
    ],
    "runArgs": [
        "-p", "${port}:${port}", 
        "--label", "devcontainer.local_folder=${PWD}",
        "--label", "devcontainer.language=${lang}",
        "--label", "devcontainer.type=claudetainer",
        "--label", "devcontainer.ssh_port=${port}"
    ],
    "forwardPorts": [
        ${port}
    ],
    "remoteEnv": {
        "CLAUDETAINER": "true",
        "NODE_OPTIONS": "--max-old-space-size=4096"
    },
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

	# Check if .devcontainer already exists
	if [[ -d ".devcontainer" ]]; then
		ui_print_warning ".devcontainer directory already exists"
		read -p "Overwrite existing .devcontainer? [y/N]: " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			ui_print_info "Aborted"
			return 1
		fi
		rm -rf .devcontainer
	fi

	# Create .devcontainer directory
	mkdir -p .devcontainer

	# Get or allocate port for this project
	local port
	if ! port=$(pm_get_project_port); then
		ui_print_error "Failed to allocate port for project"
		return 1
	fi

	# Generate devcontainer.json with allocated port and multiplexer
	devcontainer_generate_json "$language" "$port" "$multiplexer" >.devcontainer/devcontainer.json

	ui_print_success "Created .devcontainer/devcontainer.json for $language"
	ui_print_info "Allocated SSH port: $port"
	ui_print_info "Multiplexer: $multiplexer"

	return 0
}
