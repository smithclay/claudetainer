# claudetainer 📦 🤖

[![Test](https://github.com/smithclay/claudetainer/workflows/Test/badge.svg)](https://github.com/smithclay/claudetainer/actions/workflows/test.yaml)
[![Release](https://github.com/smithclay/claudetainer/workflows/Release/badge.svg)](https://github.com/smithclay/claudetainer/actions/workflows/release.yaml)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-claudetainer-blue?logo=docker)](https://github.com/smithclay/claudetainer/pkgs/container/claudetainer)
[![DevContainer Feature](https://img.shields.io/badge/devcontainer-feature-blue?logo=visualstudiocode)](https://containers.dev/features)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> Production-ish Claude Code workflows, packaged in a friendly [dev container](https://containers.dev/).

Opinionated [Claude Code](https://www.anthropic.com/claude-code) workflows: built-in instructions, slash commands, and hooks for common programming languages with built-in remote session and tmux support. Created for using Claude Code from anywhere (even your phone).

claudetainer **doesn't change your system or existing Claude Code configuration**: everything runs inside of an isolated Docker container using Anthrophic's [Claude Code dev container feature](https://github.com/anthropics/devcontainer-features). Opinionated configuration ("presets") are opt-in. You can just use claudetainer as a simple way to isolate Claude Code if you like.

## Quick Start

Get up and running in under 60 seconds on Linux, macOS or WSL:

### Option 1: Download Binary (Recommended)

```bash
# 1. Download and install latest release
curl -L https://github.com/smithclay/claudetainer/releases/latest/download/claudetainer -o claudetainer
chmod +x claudetainer && sudo mv claudetainer /usr/local/bin/

cd ~/your-project # node, python, go, rust, shell (PRs welcome for others)

# 2. Initialize your project (auto-detects language)
claudetainer init

# 3. Start your container
claudetainer up

# 4. Connect via SSH with multiplexer
claudetainer ssh
```

### Option 2: Homebrew

```bash
# 1. Add the tap and install
brew tap smithclay/tap
brew install claudetainer

cd ~/your-project # node, python, go, rust, shell (PRs welcome for others)

# 2. Initialize your project (auto-detects language)
claudetainer init

# 3. Start the container  
claudetainer up

# 4. Connect with full tooling
claudetainer ssh

# Once in the container, navigate to /workspaces and start `claude` in your project directory.
# Hooks, commands, CLAUDE.md instructions and notifications are automatically configured.

# 5. List running containers
claudetainer list

# 6. Clean up when done
claudetainer rm
```

### Option 2: Direct Download

```bash
# 1. Download and install
curl -o claudetainer https://raw.githubusercontent.com/smithclay/claudetainer/main/bin/claudetainer
chmod +x claudetainer && sudo mv claudetainer /usr/local/bin/

# 2. Follow steps 2-6 above
```

That's it! You now have a fully configured Claude Code development environment with automated linting, slash commands, and team workflows.

## What You Get

### **Zero-Config Setup**
- **Automatic language detection** - Python, Node.js, Go, Rust, Shell scripts (PRs welcome for additional languages)
- **Pre-configured linting** - black, flake8, eslint, gofmt, shellcheck 
- **Smart formatting** - Fixes code style issues automatically
- **SSH + tmux** - Remote development with persistent sessions and automatic two-window layout:
  - **claude** window for development
  - **usage** window with real-time Claude Code usage monitoring

### **Claude Code Slash Commands**
- **`/commit`** - Conventional commits with emoji and consistency
- **`/check`** - Project health and linting (useful after big changes)
- **`/next`** - Tell Claude it's time to collaborate with you on something new
- **Auto-linting** - Every file edit by Claude Code triggers code quality checks

### **Push Notifications**
- **📱 Mobile & browser notifications** - Get instant updates when Claude finishes responding, encounters errors, or needs your input
- **Zero setup required** - Automatic notification channel generation with easy-to-type URLs (claude-projectname-abc123)
- **Works everywhere** - Subscribe via https://ntfy.sh/your-channel or the [ntfy mobile app](https://ntfy.sh/) 
- **Perfect for remote coding** - Know exactly when Claude needs your attention, even when working from your phone

### **Best Practices and Extensibility**
- **Shared standards** - Load or override default configurations from remote GitHub repos
- **Enforced quality** - Blocks Calude from proceeding with unfixable issues  
- **Best practices** - Language-specific guidance built-in

## Language Support

Claudetainer automatically detects your project type and configures the right tools:

| Language | Detection Files | Tools Included | Key Features |
|----------|----------------|----------------|--------------|
| **Python** | `requirements.txt`, `pyproject.toml`, `setup.py` | black, flake8, autopep8 | Smart-lint pipeline, FastAPI patterns |
| **Node.js** | `package.json` | eslint, prettier | TypeScript support, npm/yarn detection |
| **Go** | `go.mod` | gofmt, golangci-lint | Module-aware linting |
| **Rust** | `Cargo.toml` | rustfmt, clippy | Cargo integration |
| **Shell** | `*.sh`, `install.sh`, `setup.sh`, `build.sh` | shellcheck, shfmt | POSIX/bash dialect detection, security linting |

Don't see your language? Don't like the prompts? Claudetainer is [extensible](#extending-claudetainer) - create custom presets or request new ones.

## Installation Options

### Option 1: Homebrew Package Manager

**macOS & Linux**

```bash
# Add the tap (one-time setup)
brew tap smithclay/tap

# Install claudetainer
brew install claudetainer

# Updates are easy
brew upgrade claudetainer
```

### Option 2: Direct Download

**Any Unix system** - Fallback installation method:

```bash
# Download the latest release
curl -L https://github.com/smithclay/claudetainer/releases/latest/download/claudetainer -o claudetainer

# Make executable and install
chmod +x claudetainer
sudo mv claudetainer /usr/local/bin/
```

### Option 3: Direct Dev Container Feature

Add to your existing `.devcontainer/devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/smithclay/claudetainer/claudetainer:latest": {
      "include": "python",
      "includeBase": true
    }
  }
}
```

## Example Workflows

### Python app development example

Coming soon.

## Advanced Features

### GitHub Presets - use your own standards

Don't like the defaults or want to override them?

Just reference a remote repository under `include` in `.devcontainer/.devcontainer.json` after running `claudetainer init`:

```json
{
  "features": {
    "claudetainer": {
      "include": [
        "python",
        "github:acme-corp/claude-standards/python",
        "github:acme-corp/claude-standards/security"
      ]
    }
  }
}
```

Now everyone on your team gets the same linting rules, commands, and best practices automatically. 

More details are in `DEVELOPMENT.md`.

### CLI Commands

Claudetainer provides a complete set of commands for container lifecycle management:

```bash
# Project setup
claudetainer init [language]    # Create devcontainer (auto-detects language)
claudetainer up                 # Start container (creates if missing)
claudetainer start              # Same as up

# Container management  
claudetainer ssh                # Connect with tmux session
claudetainer list               # List running containers (aliases: ps, ls)
claudetainer rm                 # Remove containers for this project
claudetainer rm --config        # Also remove .devcontainer directory
claudetainer rm -f              # Force removal without confirmation

# Debugging and health
claudetainer doctor             # Comprehensive health check
claudetainer prereqs            # Check prerequisites

# Manual SSH access
ssh -p 2223 vscode@localhost    # Password: vscode
```

### SSH Development

Connect to your container from any terminal:

```bash
claudetainer ssh
```

Includes tmux for persistent sessions that survive disconnections: perfect for talking to Claude Code from your iPhone.

## Requirements

- **Docker** - For dev container support
- **DevContainer CLI** - `npm install -g @devcontainers/cli`
- **git** - For GitHub preset support
- Claude Code and dev tools are installed automatically via dev container images and features.

### Installing Dependencies

**With Homebrew:**
```bash
# Install Node.js and DevContainer CLI
brew install node
npm install -g @devcontainers/cli

# Docker Desktop (macOS/Windows)
brew install --cask docker

# Git (usually pre-installed)
brew install git
```

**Manual Installation:**
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Node.js](https://nodejs.org/) (for DevContainer CLI)
- [Claude Code](https://claude.ai/code)

## Troubleshooting

### Quick Diagnostics
```bash
# Run comprehensive health check
claudetainer doctor

# Check prerequisites
claudetainer prereqs

# List running containers
claudetainer list
```

### Container Won't Start
```bash
# Check if devcontainer CLI is installed
devcontainer --version

# Ensure Docker is running
docker ps

# Force clean start
claudetainer rm -f && claudetainer up
```

### SSH Connection Failed
```bash
# Check if container is running
claudetainer up

# Verify port forwarding
nc -z localhost 2223

# Check container status
claudetainer list
```

### Linting Issues
```bash
# Check what tools are available
which black flake8 autopep8

# Manual lint check
~/.claude/hooks/smart-lint.sh /path/to/file.py
```

### Clean Reset
```bash
# Remove everything and start fresh
claudetainer rm -f --config
claudetainer init
claudetainer up
```

## CLI Architecture

claudetainer features a **modular architecture** designed for maintainability and easy distribution:

### Development Structure
```
bin/
├── claudetainer              # Main CLI (143 lines - 89% smaller!)
├── lib/                     # Core libraries (8 modules)
│   ├── ui.sh               # Color output and user interaction
│   ├── config.sh           # Configuration and defaults
│   ├── validation.sh       # Language/multiplexer validation
│   ├── port-manager.sh     # Port allocation and management
│   ├── docker-ops.sh       # Docker container operations
│   ├── notifications.sh    # Notification channel management
│   └── devcontainer-gen.sh # DevContainer JSON generation
├── commands/               # Command implementations (7 modules)
│   ├── doctor.sh          # Health check and diagnostics
│   ├── init.sh            # Project initialization
│   ├── up.sh              # Container startup
│   ├── ssh.sh             # SSH connection management
│   ├── rm.sh              # Container removal
│   ├── list.sh            # Container listing
│   └── prereqs.sh         # Prerequisites checking
└── dist/                   # Build output (gitignored)
    └── claudetainer        # Single-file distribution (1,435 lines)
```

### Build System
- **Development**: Use modular `./bin/claudetainer` for development
- **Distribution**: Run `./build.sh` to create `dist/claudetainer` (single file)
- **CI/CD**: Both versions tested automatically in GitHub Actions
- **Size**: Reduced main script from 1,277 to 143 lines (89% reduction!)

### Installation Methods
1. **Download Binary** (recommended): Single file from GitHub releases
2. **Homebrew**: Via `smithclay/tap` (when available)  
3. **Development**: Clone repo and use `./bin/claudetainer` directly

## Contributing

Want to improve claudetainer? Check out our [development guide](DEVELOPMENT.md) for:

- Architecture deep-dive
- Creating new presets
- Testing strategies
- Contribution workflow

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- **Documentation**: [DEVELOPMENT.md](DEVELOPMENT.md)
- **GitHub**: https://github.com/smithclay/claudetainer
- **Issues**: https://github.com/smithclay/claudetainer/issues
- **Claude Code**: https://claude.ai/code

---

Built with 🤖 for the Claude Code community
