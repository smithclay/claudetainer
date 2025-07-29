# CLAUDE.md

This file provides focused development guidance for Claude Code when working with this repository.

# Claudetainer Development

Claudetainer is a devcontainer feature that adds language-specific support to Claude Code through automated hooks, commands, sub-agents, and presets.

> **See `docs/` for complete architecture, installation, and usage documentation**

## Essential Development Commands

**IMPORTANT: ALWAYS run development checks before committing:**

```bash
make dev        # Quick check: lint + test-cli (recommended for regular dev)
make test       # Full test suite: CLI + DevContainer features + lifecycle
make check      # Comprehensive: lint + test + build (pre-commit)
make lint       # Linting: shellcheck + shfmt + scripts + JSON
make fmt        # Format all shell scripts
```

**Testing workflow:**
```bash
# Quick development cycle
./bin/claudetainer --version    # Test modular CLI
make dev                        # Run lint + CLI tests

# Full validation
make test                       # All tests (CLI + feature + lifecycle)
make build                      # Build single-file distribution
./dist/claudetainer --version   # Test built CLI
```

**YOU MUST run `make dev` successfully before any commit.**

## Key Project Structure

**Core Files:**
- `bin/claudetainer` - Modular CLI development version (143 lines)
- `dist/claudetainer` - Built single-file distribution (1,435 lines) 
- `build.sh` - Build script (modular → single-file)
- `Makefile` - Development automation and testing
- `src/claudetainer/install.sh` - DevContainer feature installation

**Important Directories:**
- `bin/lib/` - CLI library modules (8 core functions)
- `bin/commands/` - CLI command implementations 
- `src/claudetainer/presets/` - Language-specific configurations with sub-agents
- `src/claudetainer/multiplexers/` - Terminal multiplexer support
- `test/claudetainer/` - DevContainer feature tests
- `docs/` - Complete documentation

## Development Standards

**Code Style:**
- Use `rg` instead of `grep`, `fd` instead of `find`
- Graceful degradation when tools missing
- Shell scripts must pass shellcheck and shfmt formatting
- JSON files must be valid

**Testing Requirements:**
- All shell scripts executable with proper permissions
- CLI tests must pass for both modular and built versions
- DevContainer feature tests must pass all scenarios
- External lifecycle tests (27 comprehensive tests) must pass

**Architecture Principles:**
- Modular development, single-file distribution
- Sub-agent based quality control and command delegation
- Bash + Node.js utilities for JSON manipulation
- Support for external GitHub presets
- Error handling with meaningful messages

## Quick Reference

**Development commands:**
```bash
./bin/claudetainer <cmd>        # Use modular version for development
make smoke-test                 # Quick functionality test
make prereqs                    # Check development dependencies
```

**Testing commands:**
```bash
make test-cli                   # Test CLI (modular + built)
make test-feature               # Test DevContainer features
make test-lifecycle             # Test external CLI lifecycle
```

**Build and distribution:**
```bash
make build                      # Create dist/claudetainer
make install                    # Install to /usr/local/bin
make clean                      # Clean build artifacts
```

## Critical Guidelines

**IMPORTANT: Before making changes:**
1. Read existing code patterns in the affected area
2. Use the same coding style and conventions
3. Test with `make dev` before committing
4. All tests must pass - no exceptions

**YOU MUST:**
- Follow the modular architecture (bin/lib + bin/commands)
- Test both modular and built CLI versions
- Validate all JSON files are syntactically correct
- Use proper shell script formatting (shfmt)
- Handle errors gracefully with meaningful messages

**DO NOT:**
- Break the build system or single-file distribution
- Skip linting or testing steps
- Introduce dependencies not already in the project
- Change core architecture without understanding impact
