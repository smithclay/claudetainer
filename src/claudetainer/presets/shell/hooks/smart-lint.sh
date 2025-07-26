#!/usr/bin/env bash

# smart-lint.sh - Clean format-lint-fix pipeline for Shell scripts
# Pattern: FORMAT → LINT → FIX → VERIFY
#
# Designed for shell script development with shellcheck and shfmt
# Tools used: shfmt (format), shellcheck (lint), automated fixes where possible

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
    command -v "$1" &> /dev/null
}

find_shell_files() {
    # Find .sh files and files with shell shebangs
    {
        # Find .sh files
        find . -name "*.sh" \
            -not -path "./.git/*" \
            2> /dev/null || true

        # Find files with shell shebangs that aren't in .git
        find . -type f -executable \
            -not -path "./.git/*" \
            -not -name "*.py" \
            -not -name "*.js" \
            -not -name "*.ts" \
            -not -name "*.java" \
            -not -name "*.c" \
            -not -name "*.cpp" \
            -not -name "*.go" \
            -not -name "*.rs" \
            -exec file {} \; 2> /dev/null |
            grep -E "(shell script|bash script)" |
            cut -d: -f1 || true

        # Also check common script locations
        for script in install.sh setup.sh build.sh deploy.sh; do
            [[ -f "${script}" ]] && echo "./${script}"
        done
    } | sort -u
}

detect_shell_dialect() {
    local file="$1"

    # Check shebang
    if head -1 "${file}" 2> /dev/null | grep -q "#!/bin/sh"; then
        echo "sh"
    elif head -1 "${file}" 2> /dev/null | grep -q "bash"; then
        echo "bash"
    else
        # Default to bash for .sh files, sh for others
        if [[ "${file}" == *.sh ]]; then
            echo "bash"
        else
            echo "sh"
        fi
    fi
}

# =============================================================================
# CORE PIPELINE: Format → Lint → Fix → Verify
# =============================================================================

# STEP 1: FORMAT - Apply consistent formatting
format_code() {
    log "Step 1: Formatting shell scripts..."

    local files
    files=$(find_shell_files)
    [[ -z "${files}" ]] && {
        log "No shell scripts found"
        return 0
    }

    # Check tool availability first
    if ! check_tool shfmt; then
        log "WARNING: shfmt not found, skipping format"
        return 0
    fi

    local needs_formatting=false
    local file

    # Check if any files need formatting
    while IFS= read -r file; do
        [[ -z "${file}" ]] && continue
        if ! shfmt -d "${file}" &> /dev/null; then
            needs_formatting=true
            break
        fi
    done <<< "${files}"

    if [[ "${needs_formatting}" == "false" ]]; then
        log "✓ Code already formatted"
        return 0
    fi

    # Apply formatting
    log "Applying shfmt formatting..."
    while IFS= read -r file; do
        [[ -z "${file}" ]] && continue
        local dialect
        dialect=$(detect_shell_dialect "${file}")

        case "${dialect}" in
            "bash")
                shfmt -w -i 4 -bn -ci -sr "${file}" &> /dev/null || true
                ;;
            "sh")
                shfmt -w -i 4 -bn -ci -sr -p "${file}" &> /dev/null || true
                ;;
        esac
    done <<< "${files}"

    format_applied=true
    log "✓ Code formatted"
    return 0
}

# STEP 2: LINT - Check for issues
lint_code() {
    log "Step 2: Linting shell scripts..."

    local files
    files=$(find_shell_files)
    [[ -z "${files}" ]] && return 0

    # Check tool availability first
    if ! check_tool shellcheck; then
        log "WARNING: shellcheck not found, skipping lint"
        return 0
    fi

    local has_issues=false
    local file

    while IFS= read -r file; do
        [[ -z "${file}" ]] && continue
        if ! shellcheck "${file}" &> /dev/null; then
            has_issues=true
            break
        fi
    done <<< "${files}"

    if [[ "${has_issues}" == "false" ]]; then
        log "✓ No linting issues found"
        return 0
    else
        log "⚠ Linting issues detected"
        # Show the issues for debugging
        while IFS= read -r file; do
            [[ -z "${file}" ]] && continue
            echo "--- Issues in ${file} ---"
            shellcheck "${file}" || true
            echo ""
        done <<< "${files}"
        issues_remaining=true
        return 1
    fi
}

# STEP 3: FIX - Apply automatic fixes
fix_issues() {
    log "Step 3: Applying automatic fixes..."

    local files
    files=$(find_shell_files)
    [[ -z "${files}" ]] && return 0

    # Check tool availability first
    if ! check_tool shellcheck; then
        log "WARNING: shellcheck not found, skipping auto-fix"
        return 0
    fi

    # Apply common automatic fixes
    log "Applying common shell script fixes..."
    local file
    local fixed_any=false

    while IFS= read -r file; do
        [[ -z "${file}" ]] && continue
        local temp_file
        temp_file=$(mktemp)

        # Apply some simple fixes that can be automated
        # Note: This is a simplified approach. In practice, most shellcheck
        # issues require manual intervention for correctness.

        # Fix: Add quotes around variables (very basic pattern)
        if grep -q '\$[A-Za-z_][A-Za-z0-9_]*' "${file}" &&
            ! grep -q '"\$[A-Za-z_][A-Za-z0-9_]*"' "${file}"; then
            # This is a very conservative fix - only apply in simple cases
            sed 's/echo \$\([A-Za-z_][A-Za-z0-9_]*\)/echo "$\1"/g' "${file}" > "${temp_file}"
            if [[ -s "${temp_file}" ]] && diff "${file}" "${temp_file}" &> /dev/null; then
                # No changes made, skip
                rm "${temp_file}"
            else
                mv "${temp_file}" "${file}"
                fixed_any=true
            fi
        else
            rm "${temp_file}"
        fi
    done <<< "${files}"

    if [[ "${fixed_any}" == "true" ]]; then
        issues_fixed=true
        log "✓ Some auto-fixes applied"
    else
        log "✓ No automatic fixes available (manual review needed)"
    fi
    return 0
}

# STEP 4: VERIFY - Final check
verify_final() {
    log "Step 4: Final verification..."

    local files
    files=$(find_shell_files)
    [[ -z "${files}" ]] && return 0

    # Check tool availability first
    if ! check_tool shellcheck; then
        return 0
    fi

    local has_issues=false
    local file

    while IFS= read -r file; do
        [[ -z "${file}" ]] && continue
        if ! shellcheck "${file}" &> /dev/null; then
            has_issues=true
            break
        fi
    done <<< "${files}"

    if [[ "${has_issues}" == "false" ]]; then
        log "✓ All issues resolved"
        issues_remaining=false
        return 0
    else
        log "✗ Some issues remain (manual fixes needed)"
        # Show remaining issues
        while IFS= read -r file; do
            [[ -z "${file}" ]] && continue
            if ! shellcheck "${file}" &> /dev/null; then
                echo "--- Remaining issues in ${file} ---"
                shellcheck "${file}" || true
                echo ""
            fi
        done <<< "${files}"
        issues_remaining=true
        return 1
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log "Starting Shell script format-lint-fix pipeline..."

    # Environment check
    local files
    files=$(find_shell_files)
    if [[ -z "${files}" ]]; then
        log "No shell scripts detected, skipping"
        return "${EXIT_SUCCESS}"
    fi

    # Tool availability check
    local has_tools=false
    local tool
    for tool in shfmt shellcheck; do
        if check_tool "${tool}"; then
            has_tools=true
            break
        fi
    done

    if [[ "${has_tools}" == "false" ]]; then
        log "ERROR: No shell tools found (shfmt, shellcheck)"
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
