# Shell Script Best Practices

Key Principles

- Write robust, portable shell scripts with proper error handling.
- Use bash for complex scripts, POSIX sh for maximum portability.
- Always use strict error handling: `set -euo pipefail`.
- Quote variables to prevent word splitting and globbing issues.
- Use meaningful variable names with descriptive prefixes (e.g., readonly CONFIG_FILE).
- Prefer functions over duplicated code blocks.
- Use lowercase with underscores for function and variable names.
- Follow the principle of least surprise in script behavior.

Shell Script Structure

- Start with proper shebang: `#!/usr/bin/env bash` or `#!/bin/sh`.
- Include error handling early: `set -euo pipefail` for bash scripts.
- Define readonly variables and constants at the top.
- Use functions for reusable code blocks.
- Structure: constants → functions → main logic → execution guard.
- Include usage/help functions for user-facing scripts.
- Use exit codes: 0 for success, 1-255 for various error conditions.

Error Handling and Validation

- Prioritize robust error handling:
  - Use `set -e` to exit on command failures.
  - Use `set -u` to catch undefined variables.
  - Use `set -o pipefail` to catch pipeline failures.
  - Validate inputs and arguments early.
  - Use guard clauses for preconditions.
  - Provide meaningful error messages to stderr.
  - Clean up temporary files and resources on exit.
  - Use trap for cleanup on script termination.

Best Practices

- Quote all variable expansions: `"$variable"` not `$variable`.
- Use `[[ ]]` for conditionals in bash, `[ ]` for POSIX sh.
- Prefer `$()` over backticks for command substitution.
- Use `readonly` for constants and `local` for function variables.
- Check command availability with `command -v tool_name`.
- Use `find` with `-exec` or `xargs` for file operations.
- Implement proper logging with timestamps and log levels.
- Use shellcheck for static analysis and best practice validation.

Shell-Specific Tools

- **shellcheck**: Static analysis for shell scripts
- **shfmt**: Code formatter for shell scripts  
- **bash-language-server**: Language server for bash/shell
- **bats**: Bash testing framework
- **kcov**: Code coverage for shell scripts