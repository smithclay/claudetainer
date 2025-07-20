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

# Alternative: Test with devcontainer up (requires copying feature)
cp -r src/claudetainer .devcontainer/
devcontainer up --workspace-folder .

# Fallback: Manual test cycle (for quick iteration)
cp -r src/claudetainer /tmp/test-feature
export INCLUDE="python,nodejs" 
export INCLUDEBASE="true"
cd /tmp/test-feature && ./install.sh
```

**Validation:**
```bash
# Check configuration output
cat ~/.claude/settings.json | jq .
ls ~/.claude/commands/

# Run automated tests
./test/claudetainer/test.sh
```

## Implementation Notes

**Language:** Bash + Node.js utilities for JSON manipulation
**Size Target:** ~150KB total
**Dependencies:** Bash 4.0+, Node.js 16+, Claude Code 1.0+

**Preset Structure:**
- `metadata.json` - Preset metadata and dependencies
- `settings.json` - Claude Code hooks configuration  
- `commands/` - Slash commands (*.md files)
- `CLAUDE.md` - Instructions for Claude

**Merge Strategy:**
- Hooks are additive (all presets' hooks run)
- Commands override (last preset wins for same name)
- Settings deep merge
- CLAUDE.md sections concatenate

## File Structure (Target Implementation)

```
claudetainer/
├── src/claudetainer/            # Feature source (DevContainer CLI structure)
│   ├── devcontainer-feature.json    # Feature definition
│   ├── install.sh               # Main installation script
│   ├── presets/                 # Built-in language presets
│   │   ├── base/                # Universal commands
│   │   ├── python/              # Python tooling
│   │   ├── nodejs/              # JavaScript/TypeScript
│   │   └── go/                  # Go development
│   ├── lib/
│   │   ├── merge-json.js        # JSON merging utility
│   │   ├── fetch-external.sh    # GitHub preset fetcher
│   │   └── apply-preset.sh      # Preset application
│   └── bin/
│       └── claudetainer         # CLI tool
└── test/claudetainer/           # Automated tests (DevContainer CLI)
    ├── test.sh                  # Main test script
    └── scenarios.json           # Test scenarios (future)
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
3. **CI Testing**: Automated testing in GitHub Actions (future)

**Current Phase 1 Status:**
- ✅ Feature structure created (`src/claudetainer/`)
- ✅ Enhanced installation script with Node.js auto-install (`install.sh`)
- ✅ Base preset with universal commands and hooks (`presets/base/`)
- ✅ Python preset with Python-specific commands and hooks (`presets/python/`)
- ✅ Base CLAUDE.md with development guidance (`presets/base/CLAUDE.md`)
- ✅ Hello command test (`/hello`)
- ✅ Hello hook demonstration (`~/.claude/hooks/hello.sh`)
- ✅ Automated test suite with bash-only validation (`test/claudetainer/test.sh`)
- ✅ DevContainer CLI testing framework ready

**Phase 1 Implementation Details:**
- **Auto-dependency management**: Detects package manager and installs Node.js if missing
- **Cross-platform support**: Works with apt, apk, dnf, yum package managers
- **Hook system**: Demonstrates PostToolUse hook with hello.sh script
- **Preset system**: Base and Python presets with commands, hooks, and documentation
- **Pure bash testing**: Test suite uses only bash utilities for maximum compatibility
- **Error handling**: Graceful degradation with clear error messages

Track session progress:
- Files modified: install.sh (enhanced), settings.json (hooks added), test.sh (bash-only)
- Tests run: DevContainer CLI testing ready (`devcontainer features test .`)
- Outstanding issues: Local feature testing with `devcontainer up` (requires copying feature into .devcontainer/)