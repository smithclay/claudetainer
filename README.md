# claudetainer 📦 🤖

### October 2025 update: Claude Code is now available in [research preview in Anthropic's iOS app](https://www.anthropic.com/news/claude-code-on-the-web) with built-in sandboxing, this may be the official solution you're looking for :)

[![Test](https://github.com/smithclay/claudetainer/workflows/Test/badge.svg)](https://github.com/smithclay/claudetainer/actions/workflows/test.yaml)
[![Release](https://github.com/smithclay/claudetainer/workflows/Release/badge.svg)](https://github.com/smithclay/claudetainer/actions/workflows/release.yaml)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-claudetainer-blue?logo=docker)](https://github.com/smithclay/claudetainer/pkgs/container/claudetainer)
[![DevContainer Feature](https://img.shields.io/badge/devcontainer-feature-blue?logo=visualstudiocode)](https://containers.dev/features)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> Auto-configured Claude Code devcontainer with mobile-friendly shell: code from anywhere.

<p align="center">
  <img src="./assets/claudetainer-demo.gif" width="250px" alt="claudetainer-demo">
</p>

[Claude Code](https://www.anthropic.com/claude-code) automatically configured with a persistent shell session, hooks, slash commands, utilities, and specialized sub-agents designed for coding without a keyboard. Everything runs in an isolated devcontainer using Anthropic's official image.

## Quick Start (Recommended)

Get up and running in under 2 minutes on Linux, macOS or WSL:

```bash
# 1. Add the tap and install
brew tap smithclay/tap
brew install claudetainer

cd ~/your-project

# 2. Initialize your project with a language preset (go, node, python, rust)
claudetainer init python

# 3. Start the container
claudetainer up

# 4. Connect to the container with SSH key authentication (passwordless)
claudetainer ssh

# 5. (Inside the ssh session) Start Claude Code: all hooks and slash commands automatically load in a nice zellij UI.
claude
```

You now have a fully configured Claude Code development environment with specialized sub-agents, automated quality control, slash commands, and team workflows.

## Why Claudetainer?

- **🚀 Instant Setup** - Auto-detects your language (Python, Node.js, Go, Rust, Shell) and configures everything
- **📱 Code Anywhere** - SSH + terminal multiplexer designed for mobile coding (yes, even from your iPhone)
- **🔧 Smart Tooling** - Claude Code with specialized sub-agents, automatic quality control, and useful tools like ccusage and gitui
- **📬 Stay Connected** - Push notifications so you know when Claude needs attention
- **🏗️ Team Ready** - Share configurations via GitHub repos

## Requirements

- **Docker** - On macOS, using [Docker Desktop](https://www.docker.com/products/docker-desktop/) is recommended
- **DevContainer CLI** - `npm install -g @devcontainers/cli`

## Installation

**macOS & Linux (Recommended):**
```bash
# Add the tap (one-time setup)
brew tap smithclay/tap
brew install claudetainer

# Install dependencies
brew install node
npm install -g @devcontainers/cli
```

**Other systems:** [Direct download](https://github.com/smithclay/claudetainer/releases/latest/download/claudetainer) or [dev container feature](docs/INSTALLATION.md#dev-container-feature)

## Essential Commands

```bash
# Project setup
claudetainer init [language]    # Create a new devcontainer for your project
claudetainer up                 # Start container

# Connect and use
claudetainer ssh                # Connect with terminal multiplexer
claude                          # Start Claude Code (inside container)

# Management
claudetainer list               # List running containers
claudetainer doctor             # Health check and troubleshooting
claudetainer rm -f              # Clean removal
```

## Remote Development

Connect from anywhere with persistent sessions:
```bash
claudetainer mosh                # MOSH + Zellij/tmux multiplexer (better for mobile)
# Uses SSH key authentication (passwordless)
```

Includes mobile-optimized layouts and push notifications so you can code from your phone effectively.

## Advanced Configuration

- **[GitHub Presets](docs/CONFIGURATION.md#github-presets)** - Share team configurations
- **[Custom Layouts](docs/CONFIGURATION.md#layouts)** - Terminal multiplexer customization
- **[CLI Reference](docs/CLI-REFERENCE.md)** - Complete command documentation
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Detailed problem solving

## Contributing

Want to improve claudetainer? Check out our [development guide](docs/DEVELOPMENT.md) for:

- Architecture deep-dive
- Creating new presets
- Testing strategies
- Contribution workflow

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgements

Many of the original hooks and commands came from sources elsewhere in the Claude Code community, specificaly:

- https://github.com/Veraticus/nix-config/tree/main/home-manager/claude-code
- https://github.com/AizenvoltPrime/claude-setup

Huge thanks to both of those people.
