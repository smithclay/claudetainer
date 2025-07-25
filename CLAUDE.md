# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Claudetainer Development

Claudetainer is a devcontainer feature that adds language-specific support to Claude Code through automated hooks, commands, and presets.

## Key Architecture

**Core Components:**
- `src/claudetainer/` - Main devcontainer feature implementation
- `install.sh` - Bash installation script that merges presets
- `presets/` - Language-specific configurations (Python, Node.js, Go, Shell, etc.)
- `multiplexers/` - Shell multiplexer implementations (Zellij, tmux, none)
- `lib/merge-json.js` - Node.js utility for merging JSON configurations
- Phase-based implementation plan in `SPEC.md`

**Data Flow:**
```
devcontainer.json → install.sh → presets → ~/.claude/settings.json and ~/.claude/hooks
```

## Claudetainer CLI Tool

The `bin/claudetainer` CLI provides ergonomic devcontainer management with automatic language detection and multiplexer integration. The CLI now features a **modular architecture** for better maintainability and development.

**Architecture:**
- **Modular Development**: `bin/claudetainer` (143 lines) + `bin/lib/` + `bin/commands/`
- **Single-File Distribution**: `./build.sh` creates `dist/claudetainer` (1,435 lines)
- **Build System**: Smart concatenation preserves all functionality

**Installation:**
```bash
# Development (modular)
./bin/claudetainer <command>

# Build for distribution
./build.sh

# Install built version
cp ./dist/claudetainer /usr/local/bin/claudetainer

# Or download from releases
curl -L https://github.com/smithclay/claudetainer/releases/latest/download/claudetainer -o claudetainer
chmod +x claudetainer && sudo mv claudetainer /usr/local/bin/
```

**Commands:**
- `claudetainer init [language] [options]` - Create `.devcontainer` folder with claudetainer feature
  - Auto-detects language from project files if not specified
  - Supported languages: `python`, `node`, `rust`, `go`, `shell`
  - Options: `--multiplexer zellij|tmux|none` (default: zellij)
  - Generates optimized devcontainer.json with claudetainer feature
  - Creates `~/.claudetainer-credentials.json` if missing (ensures container mount point exists)

- `claudetainer up` - Start the devcontainer (wraps `devcontainer up`)
  - Requires DevContainer CLI (`npm install -g @devcontainers/cli`)
  - Validates devcontainer.json exists

- `claudetainer ssh` - SSH into running container with multiplexer session
  - Connects to dynamically allocated port with configured multiplexer
  - Creates or attaches to `claudetainer` session with development and monitoring:
    - **claude**: Main development tab/window in /workspaces
    - **usage**: Real-time Claude Code usage monitoring via ccusage
    - **Zellij**: Modern interface with floating windows and plugins
    - **tmux**: Traditional interface with familiar keybindings

- `claudetainer doctor` - Comprehensive health check and debugging
  - Validates prerequisites, container status, and configurations
  - Checks notification setup and dependency availability
  - Provides actionable guidance for fixing issues
  - Tests SSH connectivity and container health

- `claudetainer list|ps|ls` - List running containers with details
  - Shows container IDs, names, ports, status, and local folders
  - Useful for managing multiple claudetainer projects

**Language Detection:**
- **Python**: `requirements.txt`, `pyproject.toml`, `setup.py`
- **Node.js**: `package.json`
- **Rust**: `Cargo.toml`
- **Go**: `go.mod`
- **Shell**: `*.sh`, `install.sh`, `setup.sh`, `build.sh`

**Generated DevContainer Features:**
- Claude Code integration (`ghcr.io/anthropics/devcontainer-features/claude-code:1.0`)
- Claudetainer presets (`ghcr.io/smithclay/claudetainer/claudetainer:0.2.5`)
- SSH daemon for remote access (`ghcr.io/devcontainers/features/sshd:1`)
- Tmux for session management (`ghcr.io/duduribeiro/devcontainer-features/tmux:1`) - when using tmux multiplexer

**Shell Multiplexer Support:**
- **Zellij (default)**: Modern terminal workspace with intuitive UI, floating windows, WebAssembly plugins, and multiplayer collaboration
  - **Configurable layouts**: claude-dev (enhanced), claude-compact (minimal), claudetainer (basic)
  - **Custom layout support**: Via `zellij_layout` option with KDL format
  - **Auto-start integration**: Automatically starts with configured layout on SSH login
- **tmux**: Traditional, mature multiplexer with familiar keybindings and wide compatibility
- **none**: Simple bash environment for minimal setups or when multiplexers aren't needed
- Automatic session management with optimized workspace configuration
- Consistent interface across all multiplexer options

**Notification System:**
- Automatic ntfy notification channel generation (claude-projectname-hash format)
- Host-side channel persistence (`~/.claudetainer-ntfy-channel`)
- Container-side configuration (`/home/vscode/.config/claudetainer/ntfy.yaml`)
- Integration with Claude Code hooks for real-time notifications
- Easy subscription via https://ntfy.sh/your-channel or ntfy mobile app

**Usage Examples:**
```bash
# Auto-detect and initialize
claudetainer init

# Initialize specific language
claudetainer init python

# Start container
claudetainer up

# Connect via SSH with tmux
claudetainer ssh
```

## Development Commands

**Modular Architecture:**
- Main CLI: `bin/claudetainer` (143 lines - 89% reduction!)
- Libraries: `bin/lib/*.sh` (8 modules for core functionality)
- Commands: `bin/commands/*.sh` (7 modules for command implementations) 
- Build System: `./build.sh` creates single-file distribution
- Auto-tested in CI: Both modular and built versions

**Development Workflow:**
```bash
# Development: Use modular version
./bin/claudetainer doctor      # Test health check
./bin/claudetainer --version   # Test basic functionality

# Build for distribution
./build.sh                     # Creates dist/claudetainer (1,435 lines)

# Test both versions
./bin/claudetainer --help      # Modular version
./dist/claudetainer --help     # Built version

# Install for production use
cp ./dist/claudetainer /usr/local/bin/claudetainer
```

**Testing Strategy:**
```bash
# Primary: DevContainer CLI Testing (Recommended)
npm install -g @devcontainers/cli
devcontainer features test .

# CLI Testing (Modular + Built)
./bin/claudetainer --version          # Test modular
./build.sh && ./dist/claudetainer --version  # Test built

# Integration Testing
./bin/claudetainer init python        # Test modular CLI
./bin/claudetainer up                  # Test container startup
./bin/claudetainer ssh                 # Test connection

# CI Testing (automatically runs both)
# - test-cli job: Tests modular and built versions
# - test-scenarios job: Tests devcontainer features

# Test GitHub preset functionality
export INCLUDE="github:owner/repo,github:owner/repo/path/preset"
cd /tmp/test-feature && ./install.sh
```

**Validation:**
```bash
# Check configuration output
cat ~/.claude/settings.json | jq .
ls ~/.claude/commands/

# Run automated CI/CD tests
.github/workflows/test.yaml  # PR testing
.github/workflows/release.yaml  # Release workflow
```

## Implementation Notes

**Language:** Bash + Node.js utilities for JSON manipulation
**Size Target:** ~150KB total
**Dependencies:** Bash 4.0+, Node.js 16+, Claude Code 1.0+, git (for GitHub presets), Docker, DevContainer CLI

**Container Dependencies:** 
- `yq` - Required for parsing ntfy.yaml configuration in notification hooks
- `curl` - Required for sending notifications to ntfy service
- `tmux` - Session management and persistence
- Standard UNIX tools: `nc`, `lsof`, `shasum` (for port management and health checks)

**CLI Tool:** 
- Standalone `claudetainer` CLI tool at `bin/claudetainer` (v0.1.2)
- Ergonomic devcontainer management with automatic language detection
- Dynamic port allocation system (2220-2299 range) with collision avoidance
- Robust SSH access with Zellij/tmux integration and session persistence
- Comprehensive health checking via `claudetainer doctor` command
- Automatic notification channel generation and configuration

**Preset Structure:**
- `metadata.json` - Preset metadata and dependencies
- `settings.json` - Claude Code hooks configuration  
- `commands/` - Slash commands (*.md files)
- `CLAUDE.md` - Instructions for Claude

**GitHub Preset Support:**
- `github:owner/repo` - Root-level preset from GitHub repository
- `github:owner/repo/path/to/preset` - Nested preset from specific path
- Requires git to be available in the environment
- Uses shallow clones for efficiency (`--depth=1`)
- Automatic cleanup of temporary directories
- Error handling for missing repos or invalid paths

**Merge Strategy:**
- Hooks are additive (all presets' hooks run)
- Commands override (last preset wins for same name)
- Settings deep merge
- CLAUDE.md sections concatenate
- GitHub presets processed identically to local presets

## File Structure (Target Implementation)

```
claudetainer/
├── bin/
│   └── claudetainer             # Standalone CLI tool for devcontainer management
├── src/claudetainer/            # Feature source (DevContainer CLI structure)
│   ├── devcontainer-feature.json    # Feature definition
│   ├── install.sh               # Main installation script with GitHub preset support
│   ├── presets/                 # Built-in language presets
│   │   ├── base/                # Universal commands and hooks
│   │   ├── go/                  # Go development support
│   │   ├── node/                # Node.js/JavaScript/TypeScript support
│   │   ├── python/              # Python-specific tooling and hooks
│   │   ├── rust/                # Rust development support
│   │   └── shell/               # Shell script development support
│   ├── multiplexers/            # Shell multiplexer implementations
│   │   ├── base.sh              # Common multiplexer interface
│   │   ├── zellij/              # Zellij configuration and setup
│   │   ├── tmux/                # tmux configuration and setup
│   │   └── none/                # No multiplexer setup
│   ├── lib/
│   │   └── merge-json.js        # JSON merging utility for settings
│   └── scripts/
│       └── nodejs-helper.sh     # Node.js installation helper
└── test/claudetainer/           # Automated tests (DevContainer CLI)
    ├── test.sh                  # Main test script
    └── scenarios.json           # Test scenarios for different preset combinations
```

## Coding Standards

- Use `rg` instead of `grep`, `fd` instead of `find`
- Graceful degradation when tools missing
- Follow devcontainer feature spec
- Error handling with meaningful messages
- Support external GitHub presets

## Development Workflow

**Testing Phases:**
1. **Unit Testing**: DevContainer CLI automated tests (`devcontainer features test .`)
2. **Integration Testing**: Manual validation in actual devcontainer
3. **CI Testing**: Automated testing in GitHub Actions (✅ implemented)

**Current Phase 2+ Status:**
- ✅ Feature structure created (`src/claudetainer/`)
- ✅ Simplified installation script with streamlined logic (`install.sh`)
- ✅ Base preset with universal commands and hooks (`presets/base/`)
- ✅ Python preset with Python-specific commands and hooks (`presets/python/`)
- ✅ Base CLAUDE.md with development guidance (`presets/base/CLAUDE.md`)
- ✅ Enhanced JSON merging utility with Claude Code-specific rules (`lib/merge-json.js`)
- ✅ GitHub preset support with remote repository fetching (`install.sh`)
- ✅ Comprehensive test scenarios for different preset combinations (`test/claudetainer/scenarios.json`)
- ✅ DevContainer CLI testing framework with scenario support
- ✅ GitHub Actions CI/CD workflows for automated testing and publishing
- ✅ Dynamic port allocation system with collision detection and project isolation
- ✅ Notification channel generation and configuration system
- ✅ Comprehensive health checking and debugging via doctor command
- ✅ Enhanced CLI tool with robust error handling and user guidance

**Phase 2+ Implementation Details:**
- **Multi-preset merging**: Supports comma-separated preset lists with intelligent deduplication
- **GitHub preset support**: Fetches presets from remote GitHub repositories with error handling
- **Claude Code settings merging**: Permissions and hooks are properly merged and deduplicated
- **Enhanced install logic**: ~200 lines with GitHub support, robust error handling
- **Visual installation feedback**: Clear emoji-based progress indicators with GitHub fetch status
- **Robust preset handling**: Base preset included by default, no duplication
- **Enhanced testing**: Scenario-based testing for different configuration combinations
- **Shellcheck compliance**: Code follows bash best practices with proper quoting and error handling
- **Dynamic port allocation**: Hash-based port calculation with collision detection and project isolation
- **Port persistence**: Atomic file operations with locking to prevent race conditions
- **Notification system**: Automatic channel generation, host/container sync, and comprehensive debugging
- **Health monitoring**: Multi-phase doctor command covering prerequisites, containers, SSH, and notifications
- **CLI robustness**: Comprehensive error handling, user guidance, and recovery procedures

**Merge Strategy (Implemented):**
- ✅ **Hooks are merged intelligently**: Same matchers combined, commands deduplicated
- ✅ **Commands override**: Last preset wins for same command name  
- ✅ **Settings deep merge**: Permissions allow/deny lists concatenated and deduplicated
- ✅ **CLAUDE.md sections concatenate**: All preset documentation preserved with clear headers

## CI/CD Integration

**GitHub Actions Workflows:**
- `.github/workflows/test.yaml` - PR testing with DevContainer CLI
  - Tests claudetainer feature with Node.js 18 base image
  - Runs all test scenarios automatically
  - Matrix testing for different preset combinations
- `.github/workflows/release.yaml` - Automated publishing
  - Tests before deployment
  - Publishes to GitHub Container Registry (GHCR)
  - Auto-generates feature documentation
  - Creates PRs for documentation updates

**Publishing:**
- Features published to `ghcr.io/smithclay/claudetainer`
- Automatic versioning via devcontainer-feature.json
- Uses `devcontainers/action@v1` for publishing

**Usage After Publishing:**
```json
{
  "features": {
    "ghcr.io/smithclay/claudetainer:latest": {
      "include": "python,nodejs,github:acme-corp/standards/python"
    }
  }
}
```

**GitHub Preset Examples:**
```json
{
  "features": {
    "claudetainer": {
      "include": [
        "python",
        "github:acme-corp/claudetainer-standards/python",
        "github:acme-corp/claudetainer-standards/security",
        "github:my-team/custom-presets"
      ]
    }
  }
}
```

## Recent Updates (Latest Session)

**Major Features Added:**
- ✅ **Zellij Layout Configuration**: Added `zellij_layout` option to devcontainer feature for custom layout support
  - **Bundled layouts**: claude-dev (enhanced 4-tab), claude-compact (minimal 4-tab), claudetainer (basic 2-tab)
  - **Custom layout support**: Specify custom `.kdl` layout files via file path
  - **Auto-start integration**: Configured layout automatically used on SSH login
  - **Progressive fallback**: Falls back through available layouts if configured layout fails
- ✅ **Enhanced Test Coverage**: Fixed all failing test scenarios for layout configuration
  - Debugged environment variable flow from DevContainer CLI to auto-start scripts
  - Fixed HERE document variable escaping issues in bash script templates
  - Resolved function execution order problems in multiplexer installation
- ✅ **Documentation Updates**: Updated README.md and CLAUDE.md to reflect new layout functionality
- ✅ **Version Management**: Updated to v0.2.5 with zellij layout configuration support

**Files Modified:**
- `src/claudetainer/devcontainer-feature.json` - Added `zellij_layout` option and version bump to 0.2.5
- `src/claudetainer/multiplexers/zellij/install.sh` - Fixed auto-start script generation with proper variable substitution
- `src/claudetainer/multiplexers/zellij/layouts/claude-compact.kdl` - Fixed KDL syntax for test compatibility
- `test/claudetainer/test_*.sh` - All Zellij layout tests now passing
- `README.md` - Updated to document new layout configuration options
- `CLAUDE.md` - Updated to reflect latest Zellij layout functionality

**Infrastructure Improvements:**
- **Layout Configuration System**: Robust handling of custom and bundled Zellij layouts
- **Environment Variable Flow**: Proper propagation from DevContainer CLI to auto-start scripts
- **Bash Script Templates**: Fixed HERE document variable escaping for runtime execution
- **Test Coverage**: Comprehensive validation of layout configuration functionality
- **Documentation**: Updated to reflect new layout configuration capabilities
- **Version Management**: Semantic versioning with feature-based releases

**Track session progress:**
- Layout configuration feature: Added `zellij_layout` option with bundled and custom layout support
- Test debugging and fixes: Resolved all failing test scenarios for layout configuration
- Environment variable flow fixes: Proper propagation from DevContainer options to auto-start scripts
- Documentation updates: README.md and CLAUDE.md reflect new layout functionality
- Version management: Updated to v0.2.5 with Zellij layout configuration support