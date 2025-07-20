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

## Phase 1 Minimal Working Example

### Directory Structure
```
src/claudetainer/
├── devcontainer-feature.json
├── install.sh
└── presets/
    └── base/
        ├── settings.json
        ├── commands/
        │   └── check.md
        └── CLAUDE.md
```

### `devcontainer-feature.json`
```json
{
  "name": "claudetainer",
  "id": "claudetainer",
  "version": "0.1.0",
  "description": "Language support for Claude Code",
  "options": {
    "include": {
      "type": "string",
      "default": "",
      "description": "Comma-separated list of presets"
    },
    "includeBase": {
      "type": "boolean",
      "default": true,
      "description": "Include universal commands"
    }
  }
}
```

### `install.sh`
```bash
#!/bin/bash
set -e

echo "Installing Claudetainer..."

# Create Claude directories
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/scripts

# For Phase 1: Just copy base preset
cp -r /opt/claudetainer/presets/base/commands/* ~/.claude/commands/
cp /opt/claudetainer/presets/base/settings.json ~/.claude/settings.json

echo "Claudetainer installed successfully!"
```

### `presets/base/settings.json`
```json
{
  "model": "sonnet",
  "permissions": {
    "allow": [
      "Bash(cat:*)",
      "Bash(grep:*)",
      "Bash(ls:*)",
      "Bash(nix flake check:*)",
      "Bash(find:*)",
      "Bash(nixfmt-rfc-style:*)",
      "Bash(nixfmt:*)",
      "Bash(mkdir:*)",
      "Bash(cargo check:*)",
      "Bash(cargo fmt:*)",
      "Bash(cargo test:*)",
      "Bash(cargo clippy:*)",
      "Bash(rg:*)"
    ],
    "deny": []
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/smart-lint.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ntfy-notifier.sh notification"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ntfy-notifier.sh idle-notification"
          }
        ]
      }
    ]
  }
}
```

### `presets/base/commands/check.md`
```markdown
---
allowed-tools: all
description: Verify code quality, run tests, and ensure production readiness.
---

When you run `/check`, you are REQUIRED to...
```

### `presets/base/CLAUDE.md`
```markdown
# Claude-Flake Development Partnership

We're building production-quality code together. Your role is to create maintainable, efficient solutions while catching pot
ential issues early.

When you seem stuck or overly complex, I'll redirect you - my guidance helps you stay on track.

## 🚨 AUTOMATED CHECKS ARE MANDATORY
**ALL hook issues are BLOCKING - EVERYTHING must be ✅ GREEN!**
No errors. No formatting issues. No linting problems. Zero tolerance.
These are not suggestions. Fix ALL issues before continuing.

## CRITICAL WORKFLOW - ALWAYS FOLLOW THIS

### Research → Plan → Implement
**NEVER JUMP STRAIGHT TO CODING!** Always follow this sequence:
1. **Research**: Explore the codebase, understand existing patterns
2. **Plan**: Create a detailed implementation plan and verify it with me
3. **Implement**: Execute the plan with validation checkpoints
```

## Error Handling

### Missing Dependencies
```bash
handle_missing_black() {
    if ! command -v black &> /dev/null; then
        echo "Warning: Black not installed, skipping Python formatting"
        echo "Install with: pip install black"
        return 1
    fi
    return 0
}
```

### Missing Claude Code
```bash
validate_claude_code() {
    if [ ! -d "$HOME/.claude" ]; then
        echo "Error: Claude Code directory not found"
        echo "Is Claude Code feature installed?"
        echo "Add to devcontainer.json:"
        echo '  "ghcr.io/anthropics/devcontainer-features/claude-code:1.0": {}'
        exit 1
    fi
}
```

### Graceful Degradation
```bash
# In settings.json generation
generate_python_hooks() {
    local hooks='[]'
    
    if command -v black &> /dev/null; then
        hooks=$(echo "$hooks" | jq '. += [{"pattern": "*.py", "command": "black ${file}"}]')
    fi
    
    if command -v isort &> /dev/null; then
        hooks=$(echo "$hooks" | jq '. += [{"pattern": "*.py", "command": "isort ${file}"}]')
    fi
    
    echo "$hooks"
}
```

## Testing Strategy

### Unit Tests (Phase 1)
```bash
#!/bin/bash
# test/test-phase1.sh

# Setup test environment
setup() {
    export HOME="/tmp/test-home"
    mkdir -p "$HOME/.claude"
    export INCLUDE=""
    export INCLUDEBASE="true"
}

# Test base installation
test_base_install() {
    ./install.sh
    
    # Check files exist
    [ -f "$HOME/.claude/settings.json" ] || fail "settings.json not created"
    [ -f "$HOME/.claude/commands/check.md" ] || fail "check command not created"
    
    # Check command works
    output=$(bash "$HOME/.claude/commands/check.md")
    [[ "$output" == *"No language-specific"* ]] || fail "check command wrong output"
}

# Run tests
setup
test_base_install
echo "All Phase 1 tests passed!"
```

## Implementation Phases with Acceptance Criteria

### Phase 1: Minimal Viable Feature (Days 1-2)
**Goal**: Working devcontainer feature that installs successfully

**Deliverables**:
1. Basic `install.sh` that creates directories and copies files
2. Single `/hello` command that prints message
3. `devcontainer-feature.json` with proper metadata

**Acceptance Test**:
```bash
# Build test container
devcontainer build --workspace-folder test-project

# Inside container
/hello
# Expected: "Hello from Claudetainer!"

ls ~/.claude/commands/
# Expected: hello.md
```

**Success Criteria**: Feature installs without errors, command executes

### Phase 2: Base Commands & Hooks (Days 3-4)
**Goal**: Universal commands that provide value without language support

**Deliverables**:
1. Implement `/check`, `/next`, `/commit` commands
2. Basic hook system for `onTerminalCommand`
3. Simple JSON merge functionality

**Acceptance Test**:
```bash
/check
# Expected: "No language-specific checks configured"

/next
# Expected: "Analyzing project... Consider adding tests for uncovered code"

# Test hook
echo "test" > test.txt
# Should trigger onFileChange hook (if configured)
```

**Success Criteria**: All base commands work, hooks trigger

### Phase 3: Python Language Support (Days 5-6)
**Goal**: Complete Python development experience

**Deliverables**:
1. Python preset with Black, isort, pytest integration
2. Override `/check` to run Python-specific tools
3. Auto-formatting on `.py` file changes

**Acceptance Test**:
```bash
# Create poorly formatted Python
echo "def test():pass" > test.py

# Simulate Claude edit (or trigger manually)
~/.claude/scripts/trigger-hook.sh onFileChange test.py

# Check formatting
cat test.py
# Expected: Properly formatted with Black

/check
# Expected: "Running pytest... Running mypy... Running ruff..."
```

**Success Criteria**: Python files auto-format, `/check` runs Python tools

### Phase 4: Multi-Language Support (Days 7-8)
**Goal**: Support multiple languages simultaneously

**Deliverables**:
1. Node.js and Go presets
2. Proper preset merging logic
3. Language detection helpers

**Acceptance Test**:
```bash
# With include: ["python", "nodejs"]
echo "const x={a:1,b:2}" > test.js
# Should format with Prettier

echo "def test():pass" > test.py  
# Should format with Black

/check
# Should run both pytest and npm test
```

**Success Criteria**: Multiple languages coexist, correct tools run

### Phase 5: External Presets (Days 9-10)
**Goal**: Support community-created presets

**Deliverables**:
1. GitHub URL parsing and fetching
2. Preset validation
3. Caching mechanism

**Acceptance Test**:
```bash
# With include: ["github:acme/presets/custom"]
/custom-command
# Expected: Command from external preset works

# Rebuild container (should use cache)
# Expected: No re-download of external preset
```

**Success Criteria**: External presets load and cache properly

### Phase 6: CLI & Developer Tools (Days 11-12)
**Goal**: Powerful tools for preset development

**Deliverables**:
1. `claudetainer` CLI with show/list/init commands
2. Preset validation
3. Development helpers

**Acceptance Test**:
```bash
claudetainer show
# Expected: List of active presets

claudetainer validate ./my-preset
# Expected: "✓ Valid preset structure"

claudetainer plan
# Expected: Shows what would be installed
```

**Success Criteria**: CLI provides useful development feedback

## Troubleshooting During Development

### Common Issues

#### Installation Fails Silently
```bash
# Add debug mode to install.sh
if [ "${CLAUDETAINER_DEBUG}" = "true" ]; then
    set -x  # Print commands
    exec 2>/tmp/claudetainer-install.log
fi
```

#### Hooks Not Firing
1. Check Claude Code version compatibility
2. Verify settings.json syntax with `jq`
3. Test pattern matching: `echo "file.py" | grep -E "*.py"`

#### Merge Conflicts
```python
# merge-json.py debug helper
def debug_merge(base, overlay):
    print(f"Base: {json.dumps(base, indent=2)}")
    print(f"Overlay: {json.dumps(overlay, indent=2)}")
    result = merge_json(base, overlay)
    print(f"Result: {json.dumps(result, indent=2)}")
    return result
```

### Development Helpers

#### Quick Test Cycle
```bash
# dev-test.sh
#!/bin/bash
# Fast testing without rebuilding containers

# Copy files to test location
cp -r src/claudetainer /tmp/test-feature

# Simulate devcontainer environment
export INCLUDE="python,nodejs"
export INCLUDEBASE="true"

# Run installation
cd /tmp/test-feature
./install.sh

# Verify results
cat ~/.claude/settings.json | jq .
```

#### Preset Development Mode
```bash
# In install.sh
if [ "${CLAUDETAINER_DEV}" = "true" ]; then
    # Use local presets instead of installed ones
    PRESET_DIR="./presets"
    # Hot reload on file changes
    watch_presets &
fi
```

## See What's Active

Want to know what Claudetainer is doing?

```bash
claudetainer show

Active presets:
  - base (universal commands)
  - python (linting, formatting)
  - fastapi (API commands)

Active hooks:
  - onFileChange: *.py → black ${file}
  - onFileChange: *.js → prettier ${file}
  - beforeCommit: pytest --quiet

Available commands:
  - /check - Run all validations
  - /next - Get development suggestions
  - /commit - Generate commit message
  - /pytest - Run Python tests
```

---

# Advanced Usage

*Most users won't need anything below this line*

## Team Standards

Have company-wide Python standards? Share them:

```json
"include": [
  "python",
  "github:acme-corp/claudetainer-standards/python"
]
```

## Command-Line Interface

Claudetainer includes optional CLI tools:

```bash
# Check your setup
claudetainer init
✓ Claude Code detected
✓ 2 presets loaded: base, python
✓ Configuration valid

# See available presets
claudetainer list
Built-in presets:
  base      Universal commands and hooks
  python    Python development support
  nodejs    JavaScript/TypeScript support
  ...

# Preview what would change
claudetainer plan
Claudetainer will apply:
  + base preset (built-in)
  + python preset (built-in)
  ~ Override: /check command (python)

# Validate a custom preset
claudetainer validate ./my-preset
✓ metadata.json valid
✓ settings.json valid
✓ commands/ found
✓ CLAUDE.md present
```

## External Presets

Teams can create and share preset repositories:

```
github.com/acme-corp/claudetainer-standards/
├── python/           # Your Python standards
├── security/         # Security tools
└── ml-workflow/      # ML-specific commands
```

Use them with:
```json
"include": [
  "python",
  "github:acme-corp/claudetainer-standards/python",
  "github:acme-corp/claudetainer-standards/security"
]
```

### External Preset Structure
```
my-preset/
├── metadata.json      # Required: preset info
├── settings.json      # Required: Claude Code hooks
├── commands/          # Optional: custom commands
│   └── deploy.md     
├── scripts/          # Optional: helper scripts
│   └── validate.sh
└── CLAUDE.md         # Required: instructions
```

### metadata.json Example
```json
{
  "name": "python-acme",
  "version": "1.0.0",
  "description": "ACME Corp Python standards",
  "author": "ACME DevOps",
  "requires": ["python"],
  "conflicts": ["python-basic"],
  "tags": ["python", "enterprise", "security"]
}
```

## Configuration Reference

### Full Options
```json
{
  "features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:1.0": {},
    "ghcr.io/smithclay/claudetainer": {
      "include": ["python", "nodejs"],        // Array of presets
      "includeBase": true,                     // Include universal commands (default: true)
      "enableNotifications": true,             // Enable ntfy notifications (default: true)
      "claudeCodePath": "~/.claude",          // Override Claude Code location
      "debug": false                          // Enable debug logging
    }
  }
}
```

### How Presets Merge

When using multiple presets:
1. Base preset applies first (if enabled)
2. Language presets apply in array order
3. Later presets override earlier ones
4. Commands with same name get replaced
5. Hooks are additive (all run)
6. Environment variables are merged
7. CLAUDE.md sections are concatenated

#### Merge Example
```json
// Base preset
{
  "hooks": {
    "onFileChange": [
      {"pattern": "*", "command": "echo 'file changed'"}
    ]
  }
}

// Python preset
{
  "hooks": {
    "onFileChange": [
      {"pattern": "*.py", "command": "black ${file}"}
    ]
  }
}

// Result: Both hooks active
{
  "hooks": {
    "onFileChange": [
      {"pattern": "*", "command": "echo 'file changed'"},
      {"pattern": "*.py", "command": "black ${file}"}
    ]
  }
}
```

## Creating Custom Presets

### Preset Structure
```
my-preset/
├── metadata.json      # Preset metadata
├── settings.json      # Claude Code hooks
├── commands/          # Custom commands
│   └── deploy.md     
└── CLAUDE.md         # Instructions for Claude
```

### Share Your Preset
1. Push to GitHub
2. Others use it: `"include": ["github:you/repo/preset-name"]`
3. Version with tags: `"github:you/repo/preset-name@v1.0"`

## Design Principles

1. **Simple by default** - Just pick your language
2. **Progressive disclosure** - Complexity is opt-in
3. **Language-first** - Organized by what you write
4. **Zero magic** - Clear what each preset does
5. **Composable** - Mix and match as needed
6. **Fail gracefully** - Missing tools don't break everything

## Success Metrics

- New user can enable Python support in < 1 minute
- No documentation needed for basic usage
- Power users can create custom presets
- Works with any language combination
- Zero performance impact on Claude Code
- Each phase delivers working value

## Security Considerations

- External presets run arbitrary code - only use trusted sources
- Validate preset signatures (future feature)
- Sandboxed execution for hooks (future feature)
- No network access during hook execution
- Commands run with user privileges only

## Why "Claudetainer"?

It's a container of presets for Claude. Like a lunchbox of configurations. We know it's a silly name, but it's memorable! 🍱