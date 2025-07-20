#!/usr/bin/env bash

# smart-lint.sh - Lints and formats code for python inside a devcontainer
# Designed to work with https://github.com/devcontainers/features/tree/main/src/python
# 
# Assumes this python feature layer has been installed (with default options):
# "features": {
#     "ghcr.io/devcontainers/features/python:1": {}
# }
#
# Default tools installed: flake8,autopep8,black,yapf,mypy,pydocstyle,pycodestyle,bandit,pipenv,virtualenv,pytest,pylint

set -euo pipefail

handle_missing_black() {
    if ! command -v black &> /dev/null; then
        echo "Warning: Black not installed. Are you using the Python feature ghcr.io/devcontainers/features/python:1?"
        return 1
    fi
    return 0
}

echo "TODO: run python linter/formatter here"

return 2