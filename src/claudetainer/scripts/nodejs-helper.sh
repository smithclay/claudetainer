#!/bin/bash
# via https://github.com/anthropics/devcontainer-features/blob/main/src/claude-code/install.sh

# Function to detect the package manager and OS type
detect_package_manager() {
    for pm in apt-get apk dnf yum; do
        if command -v $pm >/dev/null; then
            case $pm in
                apt-get) echo "apt" ;;
                *) echo "$pm" ;;
            esac
            return 0
        fi
    done
    echo "unknown"
    return 1
}

# Function to install packages using the appropriate package manager
install_packages() {
    local pkg_manager="$1"
    shift
    local packages=("$@")

    case "$pkg_manager" in
        apt)
            apt-get update
            apt-get install -y "${packages[@]}"
            ;;
        apk)
            apk add --no-cache "${packages[@]}"
            ;;
        dnf | yum)
            $pkg_manager install -y "${packages[@]}"
            ;;
        *)
            echo "WARNING: Unsupported package manager. Cannot install packages: ${packages[*]}"
            return 1
            ;;
    esac

    return 0
}

# Function to install Node.js
install_nodejs() {
    local pkg_manager="$1"

    echo "Installing Node.js using $pkg_manager..."

    case "$pkg_manager" in
        apt)
            # Debian/Ubuntu - install more recent Node.js LTS
            install_packages apt "ca-certificates" "curl" "gnupg"
            mkdir -p /etc/apt/keyrings
            curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
            echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
            apt-get update
            apt-get install -y nodejs
            ;;
        apk)
            # Alpine
            install_packages apk "nodejs" "npm"
            ;;
        dnf)
            # Fedora/RHEL
            install_packages dnf "nodejs" "npm"
            ;;
        yum)
            # CentOS/RHEL
            curl -sL https://rpm.nodesource.com/setup_18.x | bash -
            yum install -y nodejs
            ;;
        *)
            echo "ERROR: Unsupported package manager for Node.js installation"
            return 1
            ;;
    esac

    # Verify installation
    if command -v node >/dev/null && command -v npm >/dev/null; then
        echo "Successfully installed Node.js and npm"
        return 0
    else
        echo "Failed to install Node.js and npm"
        return 1
    fi
}
