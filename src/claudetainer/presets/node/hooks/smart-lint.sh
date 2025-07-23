#!/usr/bin/env bash

# smart-lint.sh - Clean format-lint-fix pipeline for Node.js
# Pattern: FORMAT → LINT → FIX → VERIFY
#
# Designed for mcr.microsoft.com/devcontainers/javascript-node
# Tools used: prettier (format), eslint (lint+fix)

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

check_npx_tool() {
	npx --version &>/dev/null && npx "$1" --version &>/dev/null 2>&1
}

find_source_files() {
	find . \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.mjs" -o -name "*.cjs" \) \
		-not -path "./node_modules/*" \
		-not -path "./.git/*" \
		-not -path "./dist/*" \
		-not -path "./build/*" \
		-not -path "./.next/*" \
		-not -path "./coverage/*" \
		2>/dev/null || true
}

detect_config() {
	# ESLint config detection
	eslint_config=""
	for config in .eslintrc.js .eslintrc.json .eslintrc.yml .eslintrc.yaml .eslintrc package.json; do
		if [[ -f "${config}" ]]; then
			eslint_config="--config=${config}"
			break
		fi
	done

	# Prettier config detection
	prettier_config=""
	for config in .prettierrc .prettierrc.json .prettierrc.yml .prettierrc.yaml .prettierrc.js prettier.config.js package.json; do
		if [[ -f "${config}" ]]; then
			prettier_config="--config=${config}"
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
	[[ -z "${files}" ]] && {
		log "No JavaScript/TypeScript files found"
		return 0
	}

	# Check tool availability first
	if ! check_npx_tool prettier; then
		log "WARNING: prettier not found, skipping format"
		return 0
	fi

	detect_config

	# Check if formatting needed
	if echo "${files}" | xargs npx prettier --check ${prettier_config} &>/dev/null; then
		log "✓ Code already formatted"
		return 0
	fi

	# Apply formatting
	log "Applying prettier formatting..."
	echo "${files}" | xargs npx prettier --write ${prettier_config} &>/dev/null
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
	if ! check_npx_tool eslint; then
		log "WARNING: eslint not found, skipping lint"
		return 0
	fi

	detect_config

	if echo "${files}" | xargs npx eslint ${eslint_config} &>/dev/null; then
		log "✓ No linting issues found"
		return 0
	else
		log "⚠ Linting issues detected"
		# Show the issues for debugging
		echo "${files}" | xargs npx eslint ${eslint_config} || true
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
	if ! check_npx_tool eslint; then
		log "WARNING: eslint not found, skipping auto-fix"
		return 0
	fi

	detect_config

	# Apply fixes
	log "Running eslint auto-fixes..."
	echo "${files}" | xargs npx eslint ${eslint_config} --fix &>/dev/null
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
	if ! check_npx_tool eslint; then
		return 0
	fi

	detect_config

	if echo "${files}" | xargs npx eslint ${eslint_config} &>/dev/null; then
		log "✓ All issues resolved"
		issues_remaining=false
		return 0
	else
		log "✗ Some issues remain unfixable"
		echo "${files}" | xargs npx eslint ${eslint_config} || true
		issues_remaining=true
		return 1
	fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
	log "Starting Node.js format-lint-fix pipeline..."

	# Environment check
	local files
	files=$(find_source_files)
	if [[ -z "${files}" ]] && [[ ! -f "package.json" ]] && [[ ! -f "tsconfig.json" ]]; then
		log "No Node.js project detected, skipping"
		return "${EXIT_SUCCESS}"
	fi

	# Tool availability check
	local has_tools=false
	if check_npx_tool prettier || check_npx_tool eslint; then
		has_tools=true
	fi

	if [[ "${has_tools}" == "false" ]]; then
		log "ERROR: No Node.js tools found (prettier, eslint)"
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
