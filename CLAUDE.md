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
docker-compose.yml + devcontainer.json → install.sh → presets → ~/.claude/settings.json and ~/.claude/hooks
```

**Container Architecture:**
- **Docker Compose**: Provides flexible container orchestration with service definitions
- **DevContainer JSON**: Defines development environment configuration and features
- **Non-conflicting structure**: Files generated in `.devcontainer/claudetainer/` subdirectory
- **Port management**: Dynamic SSH and UDP port allocation with collision detection

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
  - Generates docker-compose.yml and devcontainer.json in `.devcontainer/claudetainer/`
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
- Claudetainer presets (`ghcr.io/smithclay/claudetainer/claudetainer:0.2.7`)
- SSH daemon for remote access (`ghcr.io/devcontainers/features/sshd:1`)
- MOSH for resilient mobile connections (`ghcr.io/devcontainers-extra/features/mosh-apt-get:1`)
- Tmux for session management (`ghcr.io/duduribeiro/devcontainer-features/tmux:1`) - when using tmux multiplexer

**Shell Multiplexer Support:**
- **Zellij (default)**: Modern terminal workspace with intuitive UI, floating windows, WebAssembly plugins, and multiplayer collaboration
  - **Configurable layouts**: tablet (enhanced with GitUI), phone (minimal with GitUI)
  - **Custom layout support**: Via `zellij_layout` option with KDL format
  - **Auto-start integration**: Automatically starts with configured layout on SSH login
  - **GitUI integration**: Visual git interface with keyboard shortcuts and fallback support
- **tmux**: Traditional, mature multiplexer with familiar keybindings and wide compatibility
- **none**: Simple bash environment for minimal setups or when multiplexers aren't needed
- Automatic session management with optimized workspace configuration
- Consistent interface across all multiplexer options

**MOSH Support:**
- **Mobile Shell (mosh)**: Provides resilient remote terminal sessions with instant feedback
  - **UDP port allocation**: Dynamic port range 60000 + SSH_PORT to 60000 + SSH_PORT + 10 
  - **NAT-friendly**: Direct port mapping ensures compatibility with Docker networking
  - **Auto-configuration**: Mosh feature automatically installed via `ghcr.io/devcontainers-extra/features/mosh-apt-get:1`
  - **Connection examples**:
    - `mosh --ssh="ssh -p 2222" --port=62222 vscode@hostname`
    - `mosh --ssh="ssh -p 2226" --port=62226 vscode@localhost`
  - **Dashboard integration**: Mobile-friendly web interface provides one-click mosh commands
  - **Benefits**: Survives network disconnections, instant character echo, works over cellular

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

# External CLI Lifecycle Testing (27 comprehensive tests)
./test/cli/lifecycle.sh ./bin/claudetainer  # Test full CLI functionality

# Integration Testing
./bin/claudetainer init python        # Test modular CLI
./bin/claudetainer up                  # Test container startup
./bin/claudetainer ssh                 # Test connection

# Makefile Testing
make test-cli                         # Test CLI (modular + built)
make test-feature                     # Test DevContainer features
make test-lifecycle                   # Test CLI lifecycle (external)
make test                            # Run all tests

# CI Testing (automatically runs all)
# - test-cli job: Tests modular and built versions
# - test-scenarios job: Tests devcontainer features
# - test-cli-lifecycle job: Tests external CLI functionality

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
- `jq` - Required for parsing ntfy.json configuration in notification hooks
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

## File Structure (Current Implementation)

```
claudetainer/
├── .devcontainer/                   # Development configuration
├── .github/workflows/               # CI/CD workflows
├── bin/                            # CLI tool implementation (modular)
│   ├── claudetainer                # Main CLI entry point (143 lines)
│   ├── commands/                   # CLI command implementations
│   │   ├── doctor.sh              # Health check and debugging
│   │   ├── init.sh                # Initialize devcontainer setup
│   │   ├── list.sh                # List running containers
│   │   ├── ssh.sh                 # SSH into container with multiplexer
│   │   └── up.sh                  # Start devcontainer
│   ├── config/                    # CLI configuration
│   └── lib/                       # Core CLI libraries
│       ├── config.sh              # Configuration management
│       ├── devcontainer-gen.sh    # DevContainer JSON generation
│       ├── docker-ops.sh          # Docker operations
│       ├── notifications.sh       # Notification system
│       ├── port-manager.sh        # Dynamic port allocation
│       ├── ui.sh                  # User interface utilities
│       └── validation.sh          # Input validation
├── src/claudetainer/              # DevContainer feature implementation
│   ├── devcontainer-feature.json # Feature definition
│   ├── install.sh                # Main installation script
│   ├── lib/
│   │   └── merge-json.js         # JSON merging utility
│   ├── multiplexers/             # Shell multiplexer implementations
│   │   ├── base.sh               # Common multiplexer interface
│   │   ├── none/                 # No multiplexer setup
│   │   ├── tmux/                 # tmux configuration and setup
│   │   └── zellij/               # Zellij configuration and setup
│   │       ├── bash-multiplexer.sh # Auto-start script
│   │       ├── config.kdl        # Zellij configuration
│   │       ├── install.sh        # Zellij installation logic
│   │       └── layouts/          # Layout definitions
│   │           ├── phone.kdl     # Compact layout
│   │           └── tablet.kdl    # Enhanced layout
│   ├── presets/                  # Language-specific presets
│   │   ├── base/                 # Universal commands and hooks
│   │   ├── go/                   # Go development support
│   │   ├── node/                 # Node.js/JavaScript/TypeScript
│   │   ├── python/               # Python-specific tooling
│   │   ├── rust/                 # Rust development support
│   │   └── shell/                # Shell script development
│   └── scripts/                  # Helper scripts
│       └── nodejs-helper.sh      # Node.js installation
├── test/                         # Testing infrastructure
│   ├── claudetainer/             # DevContainer feature tests
│   │   ├── scenarios.json        # Test scenarios
│   │   ├── test.sh              # Main test script
│   │   └── test_*.sh            # Individual scenario tests
│   └── cli/                      # External CLI tests
│       └── lifecycle.sh          # CLI lifecycle test (27 tests)
├── build.sh                      # Build script (modular → single-file)
├── dist/claudetainer             # Built single-file CLI (1,435 lines)
├── Makefile                      # Development automation
└── README.md                     # Main documentation
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

## CI/CD Integration

**GitHub Actions Workflows:**
- `.github/workflows/test.yaml` - Comprehensive PR testing
  - **test-cli job**: Tests modular and built CLI versions
  - **test-scenarios job**: Tests devcontainer features with Node.js 18 base image
  - **test-cli-lifecycle job**: Runs external CLI lifecycle test (27 comprehensive tests)
  - Tests across all test scenarios and preset combinations
- `.github/workflows/release.yaml` - Automated publishing
  - Tests before deployment
  - Publishes to GitHub Container Registry (GHCR)
  - Auto-generates feature documentation
  - Creates PRs for documentation updates

**Publishing:**
- Features published to `ghcr.io/smithclay/claudetainer`
- Automatic versioning via devcontainer-feature.json
- Uses `devcontainers/action@v1` for publishing
