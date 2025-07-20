# Claudetainer - Simple Language Support for Claude Code

> Makes Claude Code understand your programming language

## The Problem

Claude Code is great, but it doesn't know you use Python. Or that you prefer Black over yapf. Or that you always run pytest before committing.

## The Solution

Claudetainer teaches Claude Code about your language:
- Auto-formats your code after Claude edits it
- Makes `/check` actually run your tests

**Repository**: `ghcr.io/smithclay/claudetainer`  
**Language**: Bash + Python utilities  
**Size**: ~150KB

## Quick Start (30 seconds)

Add this to your `.devcontainer/devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:1.0": {},
    "ghcr.io/smithclay/claudetainer": {
      "include": ["python"]  // or "nodejs" or "go"
    }
  }
}
```

That's it. Python support enabled.

### Quick Start Test
```bash
# After container rebuild
/check
# Expected output: "Running pytest... ✓ 15 passed"

# Edit a Python file (unformatted)
echo "def test():pass" > test.py
# File should auto-format to: "def test():\n    pass"
```

## What You Get

### Before Claudetainer:
```bash
> Run my tests. I'm using pytest. Fix all test failures you see.
```

### After Claudetainer:
```bash
> /check
Running pytest... ✓ 15 passed
Running mypy... ✓ No type errors  
Running ruff... ✓ Code looks good

> /next Let's add a new FastAPI endpint "hello world"

# Claude creates a new FastAPI endpoint
# Black auto-formats it immediately ✨
```

## Claude Code Integration API

### Settings Schema

Refer to https://docs.anthropic.com/en/docs/claude-code/hooks-guide for latest docs.

Claude Code expects settings in `~/.claude/settings.json`:
```json
{
  "hooks": {
    "onFileChange": [
      {
        "pattern": "*.py",
        "command": "black ${file}",
        "silent": true
      }
    ],
    "beforeCommit": [
      {
        "command": "pytest --quiet"
      }
    ],
    "onTerminalCommand": [
      {
        "pattern": "^check$",
        "command": "~/.claude/scripts/check.sh"
      }
    ]
  },
  "environment": {
    "CLAUDE_PROJECT_TYPE": "python"
  }
}
```

### Slash Commands
Slash in `~/.claude/commands/` must follow this structure -  https://docs.anthropic.com/en/docs/claude-code/slash-commands

### Data Flow
```
┌─────────────────────────┐
│ devcontainer.json       │
│ "include": ["python"]   │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ install.sh              │
│ - Parse options         │
│ - Apply presets         │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Preset Files            │
│ - settings.json         │
│ - commands/*.md         │
│ - CLAUDE.md             │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Claude Code Directories │
│ ~/.claude/settings.json │
│ ~/.claude/commands/     │
│ ~/.claude/context.md    │
└─────────────────────────┘
```

## Prerequisites & Dependencies

### Required
- Bash 4.0+ (for associative arrays)
- Python 3.6+ (for JSON operations)
- Claude Code 1.0+ (devcontainer feature)

### Optional (graceful degradation)
- jq (fallback to Python for JSON)
- curl (fallback to wget for external presets)
- Language-specific tools (Black, Prettier, etc.)

### Base Image Compatibility
- **Debian/Ubuntu-based**: Full support, no additional steps
- **Alpine**: Requires `apk add bash python3`
- **RHEL/CentOS**: Requires `yum install python3`
- **Other**: Best effort, core features should work

### Dependency Check Example
```bash
# In install.sh
check_dependencies() {
    if ! command -v python3 &> /dev/null; then
        echo "Warning: Python 3 not found, some features disabled"
        PYTHON_CMD="true"  # no-op
    else
        PYTHON_CMD="python3"
    fi
    
    if ! command -v jq &> /dev/null; then
        echo "Info: jq not found, using Python for JSON operations"
        USE_JQ=false
    fi
}
```

## Available Languages

Just pick your language and add it to `include`:

- **`python`** - Black formatting, pytest, mypy, ruff
- **`nodejs`** - Prettier, ESLint, npm scripts
- **`go`** - gofmt, go test, race detection
- **`rust`** - cargo fmt, clippy, cargo test
- **`java`** - Google Java Format, JUnit
- **`ruby`** - RuboCop, RSpec

## Common Setups

### Python Web Development
```json
"include": ["python", "fastapi"]
```
Adds: `/create-endpoint`, `/add-model`, API testing slash commands

### Full-Stack JavaScript
```json
"include": ["nodejs", "react"]
```
Adds: `/component`, React testing, Storybook support

### Multiple Languages
```json
"include": ["python", "nodejs"]
```
Both languages work perfectly together!

## How It Works

1. **Universal Base**: Every project gets:
   - `/next` - AI suggests what to work on
   - `/commit` - Generates smart commit messages
   - `/check` - Runs validation (language-aware)
   - Notifications when Claude needs input

2. **Language Layer**: Your chosen language adds:
   - Auto-formatting after edits
   - Language-specific test running
   - Relevant slash commands
   - Best practices

3. **Framework Layer** (optional): Frameworks add specialized tools

## Architecture Overview

Claudetainer is a devcontainer feature written in **Bash** with **Python** utilities for JSON manipulation.

### Repository Structure
```
smithclay/claudetainer/                  # GitHub repo root
├── src/
│   ├── claudetainer/                    # Main feature
│   │   ├── devcontainer-feature.json    # Feature definition
│   │   ├── install.sh                   # Main installation script
│   │   ├── presets/                     # Built-in presets
│   │   │   ├── base/
│   │   │   │   ├── settings.json        # Hooks configuration
│   │   │   │   ├── commands/            # Base Claude Code slash commands
│   │   │   │   │   ├── next.md
│   │   │   │   │   ├── commit.md
│   │   │   │   │   └── check.md
│   │   │   │   └── CLAUDE.md            # Base instructions
│   │   │   ├── python/
│   │   │   │   ├── metadata.json        # Preset metadata
│   │   │   │   ├── settings.json        # Python hooks
│   │   │   │   ├── commands/
│   │   │   │   │   └── check.md         # Override base check
│   │   │   │   └── CLAUDE.md
│   │   │   ├── nodejs/
│   │   │   ├── go/
│   │   │   └── [other languages...]
│   │   ├── lib/                         # Helper scripts
│   │   │   ├── merge-json.py            # JSON merging utility
│   │   │   ├── fetch-external.sh        # GitHub preset fetcher
│   │   │   └── apply-preset.sh          # Preset application logic
│   │   └── bin/
│   │       └── claudetainer             # CLI tool (optional)
│   └── claudetainer-terminal/           # Optional SSH/tmux feature
│       ├── devcontainer-feature.json
│       └── install.sh
├── test/                                # Feature tests
├── README.md
└── LICENSE
```

### Implementation Language
Claudetainer is written in **Bash** with some **Python** utilities for JSON manipulation. This keeps it lightweight and ensures compatibility with devcontainer environments.

### How It Works
1. **Devcontainer Feature**: Claudetainer is packaged as a standard devcontainer feature
2. **Installation**: When the container builds, Claudetainer:
   - Installs preset files to `/opt/claudetainer/`
   - Parses the `include` array from options
   - Merges presets in order
   - Writes final config to Claude Code's expected locations
3. **Runtime**: No daemon needed - configurations are static files

### Technical Details
- **Total Size**: ~150KB (includes all built-in presets)
- **Dependencies**: Bash, Python 3 (for JSON ops), jq, curl (for external presets)
- **Claude Code Integration**: Writes to `~/.claude/settings.json` and `~/.claude/commands/`
- **Merge Strategy**: Later presets override earlier ones, hooks are additive
- **External Presets**: Downloaded to `/tmp` and cached in container

### Key Components

**Installation Flow** (`install.sh`):
```bash
#!/bin/bash
set -e  # Exit on error

# 1. Check dependencies
check_dependencies

# 2. Parse OPTIONS from devcontainer
IFS=',' read -ra INCLUDE_ARRAY <<< "${INCLUDE}"

# 3. Apply base preset (if enabled)
if [ "${INCLUDEBASE}" = "true" ]; then
    apply_preset "base"
fi

# 4. For each preset in include array:
for preset in "${INCLUDE_ARRAY[@]}"; do
    if [[ $preset == github:* ]]; then
        fetch_external_preset "$preset"
    fi
    apply_preset "$preset"
done

# 5. Write final merged config
python3 /opt/claudetainer/lib/merge-json.py

# 6. Install CLI tool
cp /opt/claudetainer/bin/claudetainer /usr/local/bin/

# 7. Validate installation
validate_installation
```

**Preset Merger** (`merge-json.py`):
- Hooks: Appends to arrays (all hooks run)
- Commands: Last preset wins (for same command name)
- Settings: Deep merge of JSON objects
- CLAUDE.md: Concatenates with section headers
