#!/bin/bash
# workspace-setup.sh - Auto-navigate to workspace and show custom welcome
# This gets sourced in .bashrc for SSH sessions

# Function to navigate to the workspace project directory
claudetainer_workspace_nav() {
    # Only run for login shells or when not already in workspace
    if [[ $- == *i* ]] && [[ $(pwd) != /workspaces* ]]; then
        if [[ -d /workspaces ]]; then
            # Count directories in /workspaces
            mapfile -t workspace_dirs < <(find /workspaces -maxdepth 1 -type d ! -path /workspaces)
            workspace_count=${#workspace_dirs[@]}

            if [[ $workspace_count -eq 1 ]]; then
                # Single workspace directory - navigate to it
                workspace_dir="${workspace_dirs[0]}"
                cd "$workspace_dir" 2> /dev/null || return
                echo "📁 Navigated to workspace: $(basename "$workspace_dir")"
            elif [[ $workspace_count -gt 1 ]]; then
                # Multiple directories - navigate to /workspaces and list options
                cd /workspaces 2> /dev/null || return
                echo "📁 Multiple workspaces found:"
                ls -la /workspaces/
                echo "💡 Use 'cd <workspace-name>' to enter your project"
            else
                # No workspace directories
                echo "📁 No workspace directories found in /workspaces"
            fi
        fi
    fi
}

# Function to load preset aliases
claudetainer_load_aliases() {
    preset_file="$HOME/.config/claudetainer/installed-presets.txt"
    alias_count=0

    # Only load for interactive shells
    if [[ $- != *i* ]]; then
        return 0
    fi

    # Check if preset file exists
    if [[ ! -f "$preset_file" ]]; then
        return 0
    fi

    # Load aliases from each installed preset
    while IFS= read -r preset_name; do
        # Skip empty lines
        [[ -z "$preset_name" ]] && continue

        alias_file="$HOME/.config/claudetainer/presets/$preset_name/aliases.sh"
        if [[ -f "$alias_file" ]]; then
            # Source the alias file safely
            # shellcheck disable=SC1090
            if source "$alias_file" 2> /dev/null; then
                ((alias_count++))
            fi
        fi
    done < "$preset_file"

    # Show summary if aliases were loaded
    if [[ $alias_count -gt 0 ]]; then
        echo "🔗 Loaded aliases from $alias_count preset(s)"
    fi
}

# Function to show custom welcome message
claudetainer_welcome() {
    # Only show welcome for SSH connections and login shells
    if [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" ]] && [[ $- == *i* ]]; then
        echo
        echo "Welcome to your claudetainer environment 📦 🤖"
        echo
    fi
}

# Execute workspace navigation, alias loading, and welcome
claudetainer_load_aliases
claudetainer_workspace_nav
claudetainer_welcome
