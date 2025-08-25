# Architecture

Technical details about claudetainer's design and implementation.

## Overview

claudetainer features a **modular architecture** designed for maintainability and easy distribution:

```bash
claudetainer --help              # Show all available commands
```

## CLI Architecture

The CLI uses a modular development approach with a single-file distribution build system:

**Development Structure:**
- **Modular:** `bin/claudetainer` + `bin/lib/` + `bin/commands/`
- **Libraries:** Core functionality split into focused modules
- **Commands:** Each command implemented as separate module
- **Build System:** `./build.sh` creates single-file distribution

**Distribution:**
- **Single file:** `dist/claudetainer` (self-contained)
- **No dependencies:** Pure bash with minimal external requirements
- **Portable:** Works on any Unix-like system

## DevContainer Feature

The core functionality is implemented as a DevContainer feature:

**Components:**
- `src/claudetainer/` - Main feature implementation
- `install.sh` - Feature installation script
- `presets/` - Language-specific configurations
- `multiplexers/` - Terminal multiplexer implementations

**Data Flow:**
```
docker-compose.yml + devcontainer.json → install.sh → presets → ~/.claude/
```

## Container Architecture

**Port Management:**
- Dynamic SSH port allocation (2220-2299 range)
- Collision detection and automatic assignment
- MOSH UDP port mapping for mobile connectivity

**Isolation:**
- All Claude Code configuration isolated in container
- Host system unmodified
- Project-specific containers with individual configurations

## Language Presets

**Structure:**
- `metadata.json` - Preset metadata and dependencies
- `settings.json` - Claude Code hooks configuration
- `commands/` - Slash commands (*.md files) that delegate to sub-agents
- `agents/` - Specialized sub-agents for quality control and workflows
- `CLAUDE.md` - Instructions for Claude

**Merge Strategy:**
- Hooks are additive (all presets' hooks run)
- Commands override (last preset wins for same name)
- Agents are additive (all presets' agents available)
- Settings deep merge
- CLAUDE.md sections concatenate

## Build and Testing

**Development Workflow:**
```bash
# Development: Use modular version
./bin/claudetainer <command>

# Build for distribution
./build.sh

# Test both versions
./bin/claudetainer --help      # Modular
./dist/claudetainer --help     # Built
```

**Testing Strategy:**
- **Unit:** DevContainer CLI automated tests
- **Integration:** Manual validation in containers
- **CI/CD:** GitHub Actions with comprehensive scenarios

For detailed development information, see [DEVELOPMENT.md](DEVELOPMENT.md).
