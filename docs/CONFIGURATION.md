# Configuration

Advanced configuration options for claudetainer.

## GitHub Presets

Share team configurations by referencing remote repositories in `.devcontainer/devcontainer.json`:

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

Now everyone on your team gets the same linting rules, commands, sub-agents, and best practices automatically.

## Layouts

### Multiplexer Options

```json
{
  "features": {
    "claudetainer": {
      "multiplexer": "zellij"  // zellij (default), tmux, or none
    }
  }
}
```

- **`zellij`** (default): Modern terminal workspace with intuitive UI and WebAssembly plugins
- **`tmux`**: Traditional, mature multiplexer with familiar keybindings  
- **`none`**: Simple bash environment without multiplexer

### Zellij Layout Options

```json
{
  "features": {
    "claudetainer": {
      "multiplexer": "zellij",
      "zellij_layout": "tablet"  // Layout to use
    }
  }
}
```

**Bundled Layouts:**
- **`tablet`** (default): Enhanced 4-tab workflow with GitUI integration
  - 🤖 **claude**: Main development workspace (70% + 30% split for commands)
  - 💰 **cost**: Usage monitoring + system resources  
  - 🌲 **git**: GitUI visual interface with fallback to traditional git commands
  - 🐚 **shell**: Development tasks + file explorer
- **`phone`**: Minimal 4-tab layout optimized for smaller screens
  - Single panes per tab with GitUI integration and essential functionality

**Custom Layouts:**
```json
{
  "features": {
    "claudetainer": {
      "multiplexer": "zellij", 
      "zellij_layout": "/path/to/custom-layout.kdl"
    }
  }
}
```

See the [Zellij layouts documentation](../src/claudetainer/multiplexers/zellij/README.md) for creating custom layouts.

## Push Notifications

Claudetainer automatically sets up push notifications:

- **📱 Mobile & browser notifications** - Get instant updates when Claude finishes responding
- **Zero setup required** - Automatic notification channel generation with easy-to-type URLs
- **Works everywhere** - Subscribe via https://ntfy.sh/your-channel or the [ntfy mobile app](https://ntfy.sh/) 
- **Perfect for remote coding** - Know exactly when Claude needs your attention

Notification channels follow the format: `claude-projectname-abc123`