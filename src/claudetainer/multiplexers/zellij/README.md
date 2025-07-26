# Zellij Layouts for Claude Code Development

This directory contains Zellij layout configurations optimized for Claude Code development workflows.

## Available Layouts

You can specify which layout to use via the `zellij_layout` option in your devcontainer.json:

```json
{
  "features": {
    "ghcr.io/smithclay/claudetainer": {
      "zellij_layout": "phone"
    }
  }
}
```

Or provide a custom layout file path:

```json
{
  "features": {
    "ghcr.io/smithclay/claudetainer": {
      "zellij_layout": "/path/to/my-custom-layout.kdl"
    }
  }
}
```

### 🤖 tablet.kdl (Enhanced Development Layout)
**Default for new sessions** - A comprehensive 4-tab workflow with split panes:

- **🤖 claude** (Tab 1) - Main development workspace
  - Primary Claude Code terminal (70% width)
  - Quick commands reference (30% width)
- **💰 cost** (Tab 2) - Usage and resource monitoring  
  - Real-time Claude Code usage via ccusage (60% height)
  - System resources monitor (40% height)
- **🌲 git** (Tab 3) - Interactive git operations
  - Auto-refreshing git status and log (50% width)
  - Git commands reference and shell (50% width)
- **🐚 shell** (Tab 4) - General development tasks
  - Main shell for development (70% height)
  - File explorer with auto-refresh (30% height)

### 📱 phone.kdl (Compact Layout)
**For smaller screens** - Minimal 4-tab layout with single panes:

- **🤖** - Claude Code workspace (simplified)
- **💰** - Usage monitor only
- **🌲** - Basic git status
- **🐚** - Simple shell

## Key Features

### Navigation
- **Alt+h/l** or **Alt+←/→** - Quick tab switching
- **Alt+j/k** or **Alt+↓/↑** - Pane navigation within tabs
- **Ctrl+t** - Tab management mode
- **Ctrl+p** - Pane management mode

### Development Features
- **Auto-start on SSH login** with enhanced layout by default
- **Real-time monitoring** of Claude Code usage and system resources
- **Interactive git operations** with auto-refreshing status
- **Quick command references** in dedicated panes
- **File explorer** with automatic refresh
- **Professional dark theme** (Nord-inspired)

### Usage Monitoring
- **ccusage integration** for real-time Claude Code usage tracking
- **System resource monitoring** (memory, disk, CPU)
- **Cost awareness** with usage patterns and estimates

### Git Integration
- **Auto-refreshing git status** showing current state
- **Recent commit history** with graph visualization
- **Git command reference** with common operations
- **Branch and staging information**

## Usage

### Starting Sessions
```bash
# Auto-start (enhanced layout by default)
ssh into container  # Automatically uses tablet layout

# Manual start with specific layout
zellij --layout tablet --session claudetainer      # Enhanced 4-tab
zellij --layout phone --session claudetainer  # Compact 4-tab  
```

### Switching Layouts
```bash
# From within Zellij
Ctrl+t → n → type layout name

# Or start new session
zellij --layout phone --session dev-compact
```

### Layout Selection Guide
- **tablet** - Best for development with monitoring and git workflow
- **phone** - Best for small screens or minimal setups

## Custom Layouts

### Creating Your Own Layout
You can create custom Zellij layouts in KDL format and specify them in your devcontainer.json:

1. **Create a custom layout file** (e.g., `my-workflow.kdl`):
```kdl
layout {
    default_tab_template {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        children
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }
    
    tab name="main" focus=true {
        pane {
            command "bash"
            args "-c" "echo 'My custom layout!' && exec bash"
        }
    }
}
```

2. **Reference it in devcontainer.json**:
```json
{
  "features": {
    "ghcr.io/smithclay/claudetainer": {
      "zellij_layout": "./custom-layouts/my-workflow.kdl"
    }
  }
}
```

3. **Layout Resolution**:
   - **Relative paths**: Resolved relative to the devcontainer build context
   - **Absolute paths**: Used as-is
   - **Bundled names**: `tablet`, `phone`, `claudetainer`
   - **Fallback**: If custom layout not found, falls back to `tablet`

### Layout Options
- **`tablet`** (default) - Full 4-tab development workflow
- **`phone`** - Minimal 4-tab layout for small screens
- **`claudetainer`** - Basic 2-tab layout
- **Custom path** - Your own `.kdl` layout file

## Customization

### Modifying Layouts
Edit the `.kdl` files in `~/.config/zellij/layouts/` after installation:

```bash
# Edit enhanced layout
nano ~/.config/zellij/layouts/tablet.kdl

# Edit compact layout  
nano ~/.config/zellij/layouts/phone.kdl
```

### Configuration
Main Zellij configuration at `~/.config/zellij/config.kdl` includes:
- Professional dark theme (Nord-inspired)
- Optimized keybindings for development
- Mouse support for easier navigation
- System clipboard integration
- Session persistence

## Dependencies

- **Zellij 0.42.0+** - Modern terminal multiplexer
- **ccusage** - Claude Code usage monitoring (npm package)
- **git** - Version control operations
- **Standard UNIX tools** - ls, ps, top, df, free

## Tips

1. **Use Alt+h/l** for fastest tab switching
2. **Ctrl+C in monitoring panes** to get interactive shell
3. **Git tab auto-refreshes** - Ctrl+C for manual operations
4. **File explorer refreshes** every 15 seconds
5. **System monitor refreshes** every 5 seconds
6. **Professional theme** optimized for long coding sessions

The layouts are designed to provide a comprehensive development environment while maintaining the efficiency and elegance that makes Zellij a superior choice for remote development workflows.