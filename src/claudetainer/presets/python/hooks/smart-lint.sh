#!/usr/bin/env bash

# smart-lint.sh - Clean format-lint-fix pipeline for Python
# Pattern: FORMAT → LINT → FIX → VERIFY
# 
# Designed for https://github.com/devcontainers/features/tree/main/src/python
# Tools used: black (format), flake8 (lint), autopep8 (fix)

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

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log() {
    echo "[${SCRIPT_NAME}] $*" >&2
}

check_tool() {
    command -v "$1" &>/dev/null
}

find_source_files() {
    find . -name "*.py" \
        -not -path "./.venv/*" \
        -not -path "./venv/*" \
        -not -path "./.git/*" \
        -not -path "./__pycache__/*" \
        -not -path "./.pytest_cache/*" \
        2>/dev/null || true
}

detect_config() {
    # Flake8 config detection
    flake8_config=""
    for config in setup.cfg .flake8 tox.ini pyproject.toml; do
        if [[ -f "${config}" ]]; then
            flake8_config="--config=${config}"
            break
        fi
    done
}

# =============================================================================
# CORE PIPELINE: Format → Lint → Fix → Verify
# =============================================================================

# STEP 1: FORMAT - Apply consistent formatting
format_code() {
    log "Step 1: Formatting code..."
    
    local files
    files=$(find_source_files)
    [[ -z "${files}" ]] && { log "No Python files found"; return 0; }
    
    # Check tool availability first
    if ! check_tool black; then
        log "WARNING: black not found, skipping format"
        return 0
    fi
    
    # Check if formatting needed
    if echo "${files}" | xargs black --check --diff &>/dev/null; then
        log "✓ Code already formatted"
        return 0
    fi
    
    # Apply formatting
    log "Applying black formatting..."
    echo "${files}" | xargs black &>/dev/null
    format_applied=true
    log "✓ Code formatted"
    return 0
}

# STEP 2: LINT - Check for issues  
lint_code() {
    log "Step 2: Linting code..."
    
    local files
    files=$(find_source_files)
    [[ -z "${files}" ]] && return 0
    
    # Check tool availability first
    if ! check_tool flake8; then
        log "WARNING: flake8 not found, skipping lint"
        return 0
    fi
    
    detect_config
    
    if echo "${files}" | xargs flake8 "${flake8_config}" &>/dev/null; then
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
    
    # Check tool availability first
    if ! check_tool autopep8; then
        log "WARNING: autopep8 not found, skipping auto-fix"
        return 0
    fi
    
    # Apply fixes
    log "Running autopep8 auto-fixes..."
    echo "${files}" | xargs autopep8 --in-place --aggressive &>/dev/null
    issues_fixed=true
    log "✓ Auto-fixes applied"
    return 0
}

# STEP 4: VERIFY - Final check
verify_final() {
    log "Step 4: Final verification..."
    
    local files
    files=$(find_source_files)
    [[ -z "${files}" ]] && return 0
    
    # Check tool availability first
    if ! check_tool flake8; then
        return 0
    fi
    
    detect_config
    
    if echo "${files}" | xargs flake8 "${flake8_config}" &>/dev/null; then
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
    log "Starting Python format-lint-fix pipeline..."
    
    # Environment check
    local files
    files=$(find_source_files)
    if [[ -z "${files}" ]] && [[ ! -f "pyproject.toml" ]] && [[ ! -f "setup.py" ]]; then
        log "No Python project detected, skipping"
        return "${EXIT_SUCCESS}"
    fi
    
    # Tool availability check
    local has_tools=false
    local tool
    for tool in black flake8 autopep8; do
        if check_tool "${tool}"; then
            has_tools=true
            break
        fi
    done
    
    if [[ "${has_tools}" == "false" ]]; then
        log "ERROR: No Python tools found (black, flake8, autopep8)"
        return "${EXIT_UNFIXABLE_ISSUES}"
    fi
    
    # Execute pipeline
    echo ""
    log "Pipeline: FORMAT → LINT → FIX → VERIFY"
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