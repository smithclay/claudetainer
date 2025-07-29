# Shell Script Development Standards

## Language-Specific Commands
```bash
shellcheck *.sh       # Static analysis for shell scripts
shfmt -w *.sh         # Format shell scripts
bats test/            # Run shell script tests
bash -n script.sh     # Syntax check without execution
set -x                # Debug mode for troubleshooting
```

## Code Style Preferences
- **Shebang**: Use `#!/usr/bin/env bash` for bash, `#!/bin/sh` for POSIX
- **Error Handling**: Always use `set -euo pipefail` for robust scripts
- **Quoting**: Quote all variable expansions (`"$variable"`)
- **Functions**: Use `local` for function variables, `readonly` for constants
- **Conditionals**: Use `[[ ]]` for bash, `[ ]` for POSIX compatibility
- **Documentation**: Include usage/help functions for user-facing scripts

## Shell Workflow Notes
- Use `command -v tool` to check tool availability
- Implement proper cleanup with `trap` handlers  
- Validate inputs and arguments early with guard clauses
- Use meaningful exit codes (0 = success, 1-255 for errors)
- Run `shellcheck` before commits to catch common issues
- Prefer `$()` over backticks for command substitution