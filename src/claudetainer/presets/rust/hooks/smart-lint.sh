#!/usr/bin/env bash

# smart-lint.sh - Clean format-lint-fix pipeline for Rust
# Pattern: FORMAT � LINT � FIX � VERIFY
#
# Designed for https://github.com/devcontainers/features/tree/main/src/rust
# Tools used: cargo fmt (format), cargo clippy (lint), cargo fix (fix)

set -euo pipefail

# =============================================================================
# EXTENSIBLE LANGUAGE PATTERN: Format � Lint � Fix � Verify
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
    find . -name "*.rs" \
        -not -path "./target/*" \
        -not -path "./.git/*" \
        -not -path "./vendor/*" \
        2>/dev/null || true
}

check_cargo_project() {
    [[ -f "Cargo.toml" ]]
}

# =============================================================================
# CORE PIPELINE: Format � Lint � Fix � Verify
# =============================================================================

# STEP 1: FORMAT - Apply consistent formatting
format_code() {
    log "Step 1: Formatting code..."

    local files
    files=$(find_source_files)
    [[ -z "${files}" ]] && {
        log "No Rust files found"
        return 0
    }

    # Check tool availability first
    if ! check_tool cargo; then
        log "WARNING: cargo not found, skipping format"
        return 0
    fi

    # Check if formatting needed
    if cargo fmt --check &>/dev/null; then
        log " Code already formatted"
        return 0
    fi

    # Apply formatting
    log "Applying cargo fmt formatting..."
    cargo fmt &>/dev/null
    format_applied=true
    log " Code formatted"
    return 0
}

# STEP 2: LINT - Check for issues
lint_code() {
    log "Step 2: Linting code..."

    local files
    files=$(find_source_files)
    [[ -z "${files}" ]] && return 0

    # Check tool availability first
    if ! check_tool cargo; then
        log "WARNING: cargo not found, skipping lint"
        return 0
    fi

    # Check if clippy is available
    if ! cargo clippy --version &>/dev/null; then
        log "WARNING: cargo clippy not found, skipping lint"
        return 0
    fi

    if cargo clippy --all-targets --all-features -- -D warnings &>/dev/null; then
        log " No linting issues found"
        return 0
    else
        log "� Linting issues detected"
        # Show the issues for debugging
        cargo clippy --all-targets --all-features -- -D warnings || true
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
    if ! check_tool cargo; then
        log "WARNING: cargo not found, skipping auto-fix"
        return 0
    fi

    # Apply fixes using cargo fix
    log "Running cargo fix auto-fixes..."
    if cargo fix --allow-dirty --allow-staged &>/dev/null; then
        issues_fixed=true
        log " Auto-fixes applied"
    else
        log "WARNING: cargo fix failed or no fixes available"
    fi

    # Also try clippy fixes
    if cargo clippy --version &>/dev/null; then
        log "Running cargo clippy --fix..."
        if cargo clippy --fix --allow-dirty --allow-staged &>/dev/null; then
            issues_fixed=true
            log " Clippy auto-fixes applied"
        else
            log "WARNING: cargo clippy --fix failed or no fixes available"
        fi
    fi

    return 0
}

# STEP 4: VERIFY - Final check
verify_final() {
    log "Step 4: Final verification..."

    local files
    files=$(find_source_files)
    [[ -z "${files}" ]] && return 0

    # Check tool availability first
    if ! check_tool cargo; then
        return 0
    fi

    # Check if clippy is available
    if ! cargo clippy --version &>/dev/null; then
        return 0
    fi

    if cargo clippy --all-targets --all-features -- -D warnings &>/dev/null; then
        log " All issues resolved"
        issues_remaining=false
        return 0
    else
        log " Some issues remain unfixable"
        cargo clippy --all-targets --all-features -- -D warnings || true
        issues_remaining=true
        return 1
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log "Starting Rust format-lint-fix pipeline..."

    # Environment check
    local files
    files=$(find_source_files)
    if [[ -z "${files}" ]] && ! check_cargo_project; then
        log "No Rust project detected, skipping"
        return "${EXIT_SUCCESS}"
    fi

    # Tool availability check
    if ! check_tool cargo; then
        log "ERROR: cargo not found"
        return "${EXIT_UNFIXABLE_ISSUES}"
    fi

    # Execute pipeline
    echo ""
    log "Pipeline: FORMAT � LINT � FIX � VERIFY"
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
        log "✨ Code was reformatted"
    fi

    if [[ "${issues_fixed}" == "true" ]]; then
        log "🔧 Issues were auto-fixed"
    fi

    if [[ "${issues_remaining}" == "true" ]]; then
        log "⚠️ Some issues require manual fixes"
        return "${EXIT_UNFIXABLE_ISSUES}"
    elif [[ "${format_applied}" == "true" || "${issues_fixed}" == "true" ]]; then
        log "✅ All issues resolved automatically"
        return "${EXIT_FIXED_ISSUES}"
    else
        log "✅ No issues found"
        return "${EXIT_SUCCESS}"
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
