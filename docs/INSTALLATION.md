# Installation Options

Alternative installation methods beyond the recommended Homebrew approach.

## Direct Download

**Any Unix system** - Alternative to Homebrew:

```bash
# Download the latest release
curl -L https://github.com/smithclay/claudetainer/releases/latest/download/claudetainer -o claudetainer

# Make executable and install
chmod +x claudetainer
sudo mv claudetainer /usr/local/bin/
```

## Dev Container Feature

Add to your existing `.devcontainer/devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/smithclay/claudetainer/claudetainer:latest": {
      "include": "python",
      "includeBase": true,
      "multiplexer": "zellij",
      "zellij_layout": "tablet"
    }
  }
}
```

## Dependencies Installation

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