#!/bin/bash
# SSH Library - SSH key management utilities

# Get the SSH config directory path
ssh_get_config_dir() {
    echo "$HOME/.config/claudetainer/ssh"
}

# Get the private key path
ssh_get_private_key_path() {
    local ssh_dir
    ssh_dir=$(ssh_get_config_dir)
    echo "$ssh_dir/claudetainer_rsa"
}

# Get the public key path
ssh_get_public_key_path() {
    local ssh_dir
    ssh_dir=$(ssh_get_config_dir)
    echo "$ssh_dir/claudetainer_rsa.pub"
}

# Read and return the public key content
ssh_get_public_key() {
    local public_key_path
    public_key_path=$(ssh_get_public_key_path)

    if [[ -f $public_key_path ]]; then
        cat "$public_key_path"
    else
        return 1
    fi
}

# Check if SSH keypair exists
ssh_keypair_exists() {
    local private_key_path public_key_path
    private_key_path=$(ssh_get_private_key_path)
    public_key_path=$(ssh_get_public_key_path)

    [[ -f $private_key_path ]] && [[ -f $public_key_path ]]
}

# Generate SSH keypair if it doesn't exist
ssh_ensure_keypair() {
    local ssh_dir private_key_path public_key_path
    ssh_dir=$(ssh_get_config_dir)
    private_key_path=$(ssh_get_private_key_path)
    public_key_path=$(ssh_get_public_key_path)

    # Create SSH directory if it doesn't exist
    if [[ ! -d $ssh_dir ]]; then
        ui_print_info "Creating SSH config directory: $ssh_dir"
        if ! mkdir -p "$ssh_dir"; then
            ui_print_error "Failed to create SSH config directory: $ssh_dir"
            return 1
        fi
        chmod 700 "$ssh_dir"
    fi

    # Generate keypair if it doesn't exist
    if ! ssh_keypair_exists; then
        ui_print_info "Generating SSH keypair for claudetainer..."

        if ! ssh-keygen -t rsa -b 4096 -f "$private_key_path" -N "" -C "claudetainer-$(whoami)@$(hostname)"; then
            ui_print_error "Failed to generate SSH keypair"
            return 1
        fi

        # Set correct permissions
        chmod 600 "$private_key_path"
        chmod 644 "$public_key_path"

        ui_print_success "Generated SSH keypair at $ssh_dir"
        ui_print_info "Public key:"
        echo "  $(ssh_get_public_key)"
    else
        ui_print_info "SSH keypair already exists at $ssh_dir"
    fi

    return 0
}

# Get SSH connection arguments for using the claudetainer key
ssh_get_connection_args() {
    local private_key_path
    private_key_path=$(ssh_get_private_key_path)

    if [[ -f $private_key_path ]]; then
        echo "-i $private_key_path"
    else
        # Return empty string to fall back to password authentication
        echo ""
    fi
}
