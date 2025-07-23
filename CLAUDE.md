# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Claudetainer Development

Claudetainer is a devcontainer feature that adds language-specific support to Claude Code through automated hooks, commands, and presets.

## Key Architecture

**Core Components:**
- `src/claudetainer/` - Main devcontainer feature implementation
- `install.sh` - Bash installation script that merges presets
- `presets/` - Language-specific configurations (Python, Node.js, Go, etc.)
- `lib/merge-json.js` - Node.js utility for merging JSON configurations
- Phase-based implementation plan in `SPEC.md`

**Data Flow:**
```
devcontainer.json → install.sh → presets → ~/.claude/settings.json and ~/.claude/hooks
```

## Claudetainer CLI Tool

The `bin/claudetainer` CLI provides ergonomic devcontainer management with automatic language detection and tmux integration.

**Installation:**
```bash
# Add to PATH or create symlink
ln -s /path/to/claudetainer/bin/claudetainer /usr/local/bin/claudetainer
```

**Commands:**
- `claudetainer init [language]` - Create `.devcontainer` folder with claudetainer feature
  - Auto-detects language from project files if not specified
  - Supported languages: `python`, `node`, `rust`, `go`
  - Generates optimized devcontainer.json with claudetainer feature
  - Creates `~/.claudetainer-credentials.json` if missing (ensures container mount point exists)

- `claudetainer up` - Start the devcontainer (wraps `devcontainer up`)
  - Requires DevContainer CLI (`npm install -g @devcontainers/cli`)
  - Validates devcontainer.json exists

- `claudetainer ssh` - SSH into running container with tmux session
  - Connects to dynamically allocated port with tmux integration
  - Creates or attaches to `claudetainer` tmux session

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

**Generated DevContainer Features:**
- Claude Code integration (`ghcr.io/anthropics/devcontainer-features/claude-code:1.0`)
- Claudetainer presets (`ghcr.io/smithclay/claudetainer/claudetainer:0.1.2`)
- SSH daemon for remote access (`ghcr.io/devcontainers/features/sshd:1`)
- Tmux for session management (`ghcr.io/duduribeiro/devcontainer-features/tmux:1`)

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

**Phase Development:**
- Implementation follows 6 phases outlined in `SPEC.md`
- Each phase has specific deliverables and acceptance criteria
- Start with Phase 1 (minimal working example) before proceeding

**Testing Strategy:**
```bash
# Primary: DevContainer CLI Testing (Recommended)
npm install -g @devcontainers/cli
devcontainer features test .

# Test specific feature with custom base image
devcontainer features test --feature claudetainer --base-image mcr.microsoft.com/devcontainers/javascript-node:1-18-bookworm .

# Alternative: Test with claudetainer CLI
bin/claudetainer init python
bin/claudetainer up
bin/claudetainer ssh

# Alternative: Test with devcontainer up (requires copying feature)
cp -r src/claudetainer .devcontainer/
devcontainer up --workspace-folder .

# Fallback: Manual test cycle (for quick iteration)
cp -r src/claudetainer /tmp/test-feature
export INCLUDE="python,nodejs,github:acme-corp/standards/python" 
export INCLUDEBASE="true"
cd /tmp/test-feature && ./install.sh

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
- Robust SSH access with tmux integration and session persistence
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
│   │   └── rust/                # Rust development support
│   ├── lib/
│   │   └── merge-json.js        # JSON merging utility for settings
│   ├── scripts/
│   │   └── nodejs-helper.sh     # Node.js installation helper
│   └── tmux/
│       └── .tmux.conf           # Tmux configuration
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
- ✅ **Dynamic Port Allocation System**: Hash-based port calculation with collision detection and atomic file operations
- ✅ **Notification Channel Generation**: Automatic ntfy channel creation with easy-to-type format (claude-projectname-hash)
- ✅ **Comprehensive Health Checking**: Multi-phase doctor command with 8 diagnostic areas
- ✅ **Enhanced CLI Tool**: Robust error handling, user guidance, and recovery procedures
- ✅ **Version Management**: Updated to v0.1.2 with improved feature stability

**Files Modified:**
- `bin/claudetainer` - Added port allocation, notification setup, and doctor command enhancements
- `src/claudetainer/devcontainer-feature.json` - Version bump to 0.1.2
- `.github/workflows/` - Simplified workflow names and improved documentation
- `README.md` - Updated documentation and badge links

**Infrastructure Improvements:**
- **Port Management**: 2220-2299 range with project-specific allocation and persistence
- **Container Lifecycle**: Automatic notification setup during container startup
- **Debugging Tools**: Comprehensive diagnostics for all system components
- **Error Recovery**: Clear guidance and automated fixes for common issues

**Track session progress:**
- Major architectural improvements: port allocation system, notification integration
- Enhanced user experience: comprehensive debugging, better error messages
- Infrastructure hardening: atomic operations, race condition prevention
- Documentation updates: workflow names, feature descriptions, usage examples
- Version management: semantic versioning with feature stability tracking