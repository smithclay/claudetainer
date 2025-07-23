# Claudetainer

[![Test](https://github.com/smithclay/claudetainer/workflows/Test/badge.svg)](https://github.com/smithclay/claudetainer/actions/workflows/test.yaml)
[![Release](https://github.com/smithclay/claudetainer/workflows/Release/badge.svg)](https://github.com/smithclay/claudetainer/actions/workflows/release.yaml)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-claudetainer-blue?logo=docker)](https://github.com/smithclay/claudetainer/pkgs/container/claudetainer)
[![DevContainer Feature](https://img.shields.io/badge/devcontainer-feature-blue?logo=visualstudiocode)](https://containers.dev/features)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> Production-ready Claude Code workflows, packaged in a friendly [dev container](https://containers.dev/)

Opinionated [Claude Code](https://www.anthropic.com/claude-code) workflows: built-in instructions, slash commands, and hooks for common programming languages with built-in remote session and tmux support. Created for using Claude Code from anywhere (even your phone).

claudetainer **doesn't change your system or existing Claude Code configuration**: everything runs inside of an isolated Docker container using Anthrophic's [Claude Code dev container feature](https://github.com/anthropics/devcontainer-features). Configuration is opt-in, and you can just use claudetainer as a simple way to isolate Claude Code if you like.

## Quick Start

Get up and running in under 60 seconds:

### Option 1: Homebrew (Recommended)

```bash
# 1. Add the tap and install
brew tap smithclay/tap
brew install claudetainer

cd ~/your-project # node, python, go, rust (PRs welcome for others)

# 2. Initialize your project (auto-detects language)
claudetainer init

# 3. Start the container  
claudetainer up

# 4. Connect with full tooling
claudetainer ssh

# Once in the container, navigate to /workspaces and start `claude` in your project directory.

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
- **Automatic language detection** - Python, Node.js, Go, Rust (PRs welcome for additional languages)
- **Pre-configured linting** - black, flake8, eslint, gofmt 
- **Smart formatting** - Fixes code style issues automatically
- **SSH + tmux** - Remote development with persistent sessions (for using Claude Code on your phone)

### **Claude Code Slash Commands**
- **`/commit`** - Conventional commits with emoji and consistency
- **`/check`** - Project health and linting (useful after big changes)
- **`/next`** - Tell Claude it's time to collaborate with you on something new
- **Auto-linting** - Every file edit by Claude Code triggers code quality checks

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

### Automated Code Quality

Every time you edit a file, claudetainer automatically:

```bash
# Python example - runs after each file save
✅ Formatting with black...
✅ Linting with flake8...  
✅ Auto-fixing with autopep8...
✅ All checks passed!
```

If there are unfixable issues, Claude Code operations are blocked until you fix them - ensuring your code stays clean.

### Smart Git Commits

Use the `/commit` slash command for consistent commits:

```bash
/commit "add user authentication system"

# Results in:
✨ feat: add user authentication system

🔧 Changes:
- Add JWT token validation
- Implement user login/logout endpoints
- Add password hashing with bcrypt

📋 Files changed: 5 files (+127, -23)
```

### Use your own standards

Have your own standards and defaults for particular languages or projects?

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

Now everyone on your team gets the same linting rules, commands, and best practices automatically. More details are in `DEVELOPMENT.md`.

## Advanced Features

### GitHub Presets

Share configurations across teams using GitHub repositories:

- **`github:owner/repo`** - Use entire repo as preset
- **`github:owner/repo/path/preset`** - Use specific directory
- **Automatic updates** - Pull latest standards on container rebuild
- **Private repos supported** - Uses your git credentials

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

Built with ❤️ for the Claude Code community