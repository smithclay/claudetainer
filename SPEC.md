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
```javascript
// merge-json.js debug helper
function debugMerge(base, overlay) {
    console.log("Base:", JSON.stringify(base, null, 2));
    console.log("Overlay:", JSON.stringify(overlay, null, 2));
    const result = mergeJson(base, overlay);
    console.log("Result:", JSON.stringify(result, null, 2));
    return result;
}
```

### Development Helpers

#### DevContainer CLI Test Cycle (Recommended)
```bash
# Primary testing method
npm install -g @devcontainers/cli
devcontainer features test .

# Test specific scenarios (future phases)
devcontainer features test . --scenarios python,nodejs
```

#### Quick Manual Test Cycle (Fallback)
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