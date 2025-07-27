#!/usr/bin/env bash

# smart-lint.sh - Modern format-lint-fix pipeline for Python using uv + ruff
# Pattern: FORMAT → LINT → FIX → VERIFY
#
# Designed for modern Python development with uv package manager
# Tools used: ruff (format + lint + fix), mypy (type checking), uv (tool execution)

set -euo pipefail

# =============================================================================
# EXTENSIBLE LANGUAGE PATTERN: Format → Lint → Fix → Verify
# =============================================================================

readonly SCRIPT_NAME="smart-lint"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_FIXED_ISSUES=1
readonly EXIT_UNFIXABLE_ISSUES=2

# Results tracking
format_applied=false
issues_fixed=false
issues_remaining=false

# Tool command variables (set by detect_ruff_command)
ruff_cmd=""
mypy_cmd=""

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log() {
    echo "[${SCRIPT_NAME}] $*" >&2
}

check_tool() {
    command -v "$1" &> /dev/null
}

find_source_files() {
    find . -name "*.py" \
        -not -path "./.venv/*" \
        -not -path "./venv/*" \
        -not -path "./.uv-cache/*" \
        -not -path "./.git/*" \
        -not -path "./__pycache__/*" \
        -not -path "./.pytest_cache/*" \
        -not -path "./.ruff_cache/*" \
        -not -path "./.mypy_cache/*" \
        2> /dev/null || true
}

detect_project_type() {
    # Detect if this is a uv project or traditional Python project
    use_uv=false
    has_ruff_config=false

    if check_tool uv; then
        # Strong indicators of uv project
        if [[ -f "uv.lock" ]] || [[ -f ".python-version" ]]; then
            use_uv=true
        elif [[ -f "pyproject.toml" ]]; then
            # Check for uv-specific sections in pyproject.toml
            if grep -q -E "(tool\.uv|dependency-groups)" pyproject.toml 2> /dev/null; then
                use_uv=true
            fi
        fi

        # Check for ruff configuration files
        if [[ -f "ruff.toml" ]] || [[ -f ".ruff.toml" ]] || grep -q "tool.ruff" pyproject.toml 2> /dev/null; then
            has_ruff_config=true
        fi

        # Fallback to uv if available and no legacy files, but has modern indicators
        if [[ "${use_uv}" == "false" ]] && [[ ! -f "requirements.txt" ]] && [[ ! -f "setup.py" ]]; then
            if [[ -f "pyproject.toml" ]] || [[ "${has_ruff_config}" == "true" ]]; then
                use_uv=true
            fi
        fi
    fi
}

detect_ruff_command() {
    # Detect best way to execute ruff and set global variables
    ruff_cmd=""
    mypy_cmd=""

    if [[ "${use_uv}" == "true" ]]; then
        # Try different execution strategies for ruff
        if uv run --no-project ruff --version 2> /dev/null; then
            ruff_cmd="uv run --no-project ruff"
        elif uv run ruff --version 2> /dev/null; then
            ruff_cmd="uv run ruff"
        elif check_tool uvx && uvx ruff --version 2> /dev/null; then
            ruff_cmd="uvx ruff"
        elif check_tool ruff; then
            ruff_cmd="ruff"
        fi

        # Try different execution strategies for mypy
        if uv run --no-project mypy --version 2> /dev/null; then
            mypy_cmd="uv run --no-project mypy"
        elif uv run mypy --version 2> /dev/null; then
            mypy_cmd="uv run mypy"
        elif check_tool uvx && uvx mypy --version 2> /dev/null; then
            mypy_cmd="uvx mypy"
        elif check_tool mypy; then
            mypy_cmd="mypy"
        fi
    fi
}

# =============================================================================
# CORE PIPELINE: Format → Lint → Fix → Verify
# =============================================================================

# STEP 1: FORMAT - Apply consistent formatting
format_code() {
    log "Step 1: Formatting code..."

    local files
    files=$(find_source_files)
    [[ -z "${files}" ]] && {
        log "No Python files found"
        return 0
    }

    if [[ "${use_uv}" == "true" ]]; then
        # Modern uv + ruff approach
        if [[ -z "${ruff_cmd}" ]]; then
            log "ERROR: Ruff not accessible via any method"
            return 1
        fi

        # Check if formatting needed
        if ${ruff_cmd} format --check . 2> /dev/null; then
            log "✓ Code already formatted"
            return 0
        fi

        # Apply formatting
        log "Applying ruff formatting..."
        if ${ruff_cmd} format . 2> /dev/null; then
            format_applied=true
            log "✓ Code formatted with ruff"
        else
            log "ERROR: Ruff formatting failed"
            return 1
        fi
        return 0
    else
        format_code_legacy
    fi
}

format_code_legacy() {
    # Legacy black formatting
    if ! check_tool black; then
        log "WARNING: black not found, skipping format"
        return 0
    fi

    local files
    files=$(find_source_files)

    # Check if formatting needed
    if echo "${files}" | xargs black --check --diff &> /dev/null; then
        log "✓ Code already formatted"
        return 0
    fi

    # Apply formatting
    log "Applying black formatting..."
    echo "${files}" | xargs black &> /dev/null
    format_applied=true
    log "✓ Code formatted with black"
    return 0
}

# STEP 2: LINT - Check for issues
lint_code() {
    log "Step 2: Linting code..."

    local files
    files=$(find_source_files)
    [[ -z "${files}" ]] && return 0

    if [[ "${use_uv}" == "true" ]]; then
        # Modern uv + ruff approach
        if [[ -z "${ruff_cmd}" ]]; then
            log "ERROR: Ruff not accessible via any method"
            return 1
        fi

        if ${ruff_cmd} check . 2> /dev/null; then
            log "✓ No linting issues found"
            return 0
        else
            log "⚠ Linting issues detected"
            # Show the issues for debugging
            ${ruff_cmd} check . || true
            issues_remaining=true
            return 1
        fi
    else
        lint_code_legacy
    fi
}

lint_code_legacy() {
    # Legacy flake8 linting
    if ! check_tool flake8; then
        log "WARNING: flake8 not found, skipping lint"
        return 0
    fi

    local files
    files=$(find_source_files)

    # Detect flake8 config
    local flake8_config=""
    for config in setup.cfg .flake8 tox.ini pyproject.toml; do
        if [[ -f "${config}" ]]; then
            flake8_config="--config=${config}"
            break
        fi
    done

    if echo "${files}" | xargs flake8 "${flake8_config}" &> /dev/null; then
        log "✓ No linting issues found"
        return 0
    else
        log "⚠ Linting issues detected"
        # Show the issues for debugging
        echo "${files}" | xargs flake8 "${flake8_config}" || true
        issues_remaining=true
        return 1
    fi
}

# STEP 3: FIX - Apply automatic fixes
fix_issues() {
    log "Step 3: Applying automatic fixes..."

    local files
    files=$(find_source_files)
    [[ -z "${files}" ]] && return 0

    if [[ "${use_uv}" == "true" ]]; then
        # Modern uv + ruff approach
        if [[ -z "${ruff_cmd}" ]]; then
            log "ERROR: Ruff not accessible via any method"
            return 1
        fi

        # Apply fixes
        log "Running ruff auto-fixes..."
        if ${ruff_cmd} check --fix . 2> /dev/null; then
            issues_fixed=true
            log "✓ Auto-fixes applied with ruff"
        else
            log "✓ No auto-fixable issues found"
        fi
        return 0
    else
        fix_issues_legacy
    fi
}

fix_issues_legacy() {
    # Legacy autopep8 fixes
    if ! check_tool autopep8; then
        log "WARNING: autopep8 not found, skipping auto-fix"
        return 0
    fi

    local files
    files=$(find_source_files)

    # Apply fixes
    log "Running autopep8 auto-fixes..."
    echo "${files}" | xargs autopep8 --in-place --aggressive &> /dev/null
    issues_fixed=true
    log "✓ Auto-fixes applied with autopep8"
    return 0
}

# STEP 4: VERIFY - Final check
verify_final() {
    log "Step 4: Final verification..."

    local files
    files=$(find_source_files)
    [[ -z "${files}" ]] && return 0

    if [[ "${use_uv}" == "true" ]]; then
        # Modern uv + ruff approach
        if [[ -z "${ruff_cmd}" ]]; then
            log "ERROR: Ruff not accessible via any method"
            return 1
        fi

        # Run both ruff check and type check if mypy is available
        local ruff_ok=true
        local mypy_ok=true

        if ! ${ruff_cmd} check . 2> /dev/null; then
            log "✗ Ruff issues remain"
            ${ruff_cmd} check . || true
            ruff_ok=false
        fi

        # Optional type checking with mypy
        if [[ -n "${mypy_cmd}" ]]; then
            if ! ${mypy_cmd} . --ignore-missing-imports 2> /dev/null; then
                log "⚠ Type checking issues found"
                ${mypy_cmd} . --ignore-missing-imports || true
                mypy_ok=false
            fi
        fi

        if [[ "${ruff_ok}" == "true" ]]; then
            if [[ "${mypy_ok}" == "true" && -n "${mypy_cmd}" ]]; then
                log "✓ All issues resolved (ruff + mypy)"
            elif [[ "${mypy_ok}" == "false" ]]; then
                log "✓ All ruff issues resolved (mypy warnings)"
            else
                log "✓ All ruff issues resolved"
            fi
            issues_remaining=false
            return 0
        else
            issues_remaining=true
            return 1
        fi
    else
        verify_final_legacy
    fi
}

verify_final_legacy() {
    # Legacy flake8 verification
    if ! check_tool flake8; then
        return 0
    fi

    local files
    files=$(find_source_files)

    # Detect flake8 config
    local flake8_config=""
    for config in setup.cfg .flake8 tox.ini pyproject.toml; do
        if [[ -f "${config}" ]]; then
            flake8_config="--config=${config}"
            break
        fi
    done

    if echo "${files}" | xargs flake8 "${flake8_config}" &> /dev/null; then
        log "✓ All issues resolved"
        issues_remaining=false
        return 0
    else
        log "✗ Some issues remain unfixable"
        echo "${files}" | xargs flake8 "${flake8_config}" || true
        issues_remaining=true
        return 1
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log "Starting modern Python format-lint-fix pipeline..."

    # Environment check
    local files
    files=$(find_source_files)
    if [[ -z "${files}" ]] && [[ ! -f "pyproject.toml" ]] && [[ ! -f "setup.py" ]]; then
        log "No Python project detected, skipping"
        return "${EXIT_SUCCESS}"
    fi

    # Detect project type and tools
    detect_project_type

    if [[ "${use_uv}" == "true" ]]; then
        log "Detected uv project - using modern ruff + mypy pipeline"
        if ! check_tool uv; then
            log "ERROR: uv not found but required for this project"
            return "${EXIT_UNFIXABLE_ISSUES}"
        fi

        # Check if ruff is available and install if needed
        if ! uv run --no-project ruff --version 2> /dev/null && ! uv run ruff --version 2> /dev/null; then
            log "Ruff not found - attempting installation..."

            # Try different installation strategies
            local install_success=false

            # Strategy 1: Add as dev dependency if pyproject.toml exists
            if [[ -f "pyproject.toml" ]] && uv add --dev ruff mypy 2> /dev/null; then
                log "✓ Installed ruff and mypy as dev dependencies"
                install_success=true
            # Strategy 2: Initialize project and add dependencies
            elif [[ ! -f "pyproject.toml" ]] && uv init --no-readme . 2> /dev/null && uv add --dev ruff mypy 2> /dev/null; then
                log "✓ Initialized uv project and installed ruff and mypy"
                install_success=true
            # Strategy 3: Use uv tool for global installation
            elif uv tool install ruff 2> /dev/null && uv tool install mypy 2> /dev/null; then
                log "✓ Installed ruff and mypy as global tools"
                install_success=true
            fi

            if [[ "${install_success}" == "false" ]]; then
                log "⚠ Failed to install ruff, falling back to legacy tools"
                use_uv=false
            fi
        fi
    fi

    # Detect available tool commands after installation attempts
    if [[ "${use_uv}" == "true" ]]; then
        detect_ruff_command
        if [[ -z "${ruff_cmd}" ]]; then
            log "⚠ Ruff still not available, falling back to legacy tools"
            use_uv=false
        else
            log "Using ruff via: ${ruff_cmd}"
            if [[ -n "${mypy_cmd}" ]]; then
                log "Using mypy via: ${mypy_cmd}"
            fi
        fi
    fi

    if [[ "${use_uv}" == "false" ]]; then
        log "Using legacy Python tools pipeline"
        # Tool availability check for legacy tools
        local has_tools=false
        local tool
        for tool in black flake8 autopep8; do
            if check_tool "${tool}"; then
                has_tools=true
                break
            fi
        done

        if [[ "${has_tools}" == "false" ]]; then
            log "ERROR: No Python tools found (black, flake8, autopep8, ruff)"
            log "Please install tools with: pip install black flake8 autopep8"
            log "Or for modern setup: uv add --dev ruff mypy"
            return "${EXIT_UNFIXABLE_ISSUES}"
        fi
    fi

    # Execute pipeline
    echo ""
    if [[ "${use_uv}" == "true" ]]; then
        log "Pipeline: RUFF FORMAT → RUFF LINT → RUFF FIX → VERIFY (+ MYPY)"
    else
        log "Pipeline: BLACK FORMAT → FLAKE8 LINT → AUTOPEP8 FIX → VERIFY"
    fi
    echo ""

    format_code

    # Check lint results but don't exit on failure
    lint_code
    # Continue to fix phase regardless of lint results

    fix_issues

    # Check final verification but don't exit on failure
    verify_final
    # We'll report results below regardless of verification results

    # Report results
    echo ""
    log "RESULTS:"
    log "========"

    if [[ "${format_applied}" == "true" ]]; then
        log "• Code was reformatted"
    fi

    if [[ "${issues_fixed}" == "true" ]]; then
        log "• Issues were auto-fixed"
    fi

    if [[ "${issues_remaining}" == "true" ]]; then
        log "• Some issues require manual fixes"
        return "${EXIT_UNFIXABLE_ISSUES}"
    elif [[ "${format_applied}" == "true" || "${issues_fixed}" == "true" ]]; then
        log "• All issues resolved automatically"
        return "${EXIT_FIXED_ISSUES}"
    else
        log "• No issues found"
        return "${EXIT_SUCCESS}"
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
