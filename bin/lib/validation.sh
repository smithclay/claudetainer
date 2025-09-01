#!/bin/bash
# Validation Library - Language and multiplexer validation

# Detect project language based on files present
validation_detect_language() {
    if [[ -f "package.json" ]]; then
        echo "node"
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        echo "python"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "mix.exs" ]]; then
        echo "elixir"
    elif [[ -f "install.sh" ]] || [[ -f "setup.sh" ]] || [[ -f "build.sh" ]] || find . -maxdepth 2 -name "*.sh" -type f | head -1 | grep -q .; then
        echo "shell"
    else
        echo ""
    fi
}

# Validate language is supported
validation_validate_language() {
    local lang="$1"
    case "$lang" in
    python | node | rust | go | elixir | shell | base)
        return 0
        ;;
    *)
        ui_print_error "Unsupported language: $lang"
        echo "Supported languages: python, node, rust, go, elixir, shell, base"
        return 1
        ;;
    esac
}

# Validate multiplexer is supported
validation_validate_multiplexer() {
    local multiplexer="$1"
    case "$multiplexer" in
    zellij | tmux | none)
        return 0
        ;;
    *)
        ui_print_error "Unsupported multiplexer: $multiplexer"
        echo "Supported multiplexers: zellij, tmux, none"
        return 1
        ;;
    esac
}
