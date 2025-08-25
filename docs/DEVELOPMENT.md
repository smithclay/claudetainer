# Development Guide

> Technical documentation for claudetainer contributors and preset authors

This guide covers the technical architecture, development workflows, and contribution processes for claudetainer.

## Architecture Overview

Claudetainer is a **DevContainer feature** that integrates Claude Code with language-specific development workflows through a preset-based architecture.

### Core Components

```
claudetainer/
├── bin/claudetainer              # Standalone CLI tool
├── src/claudetainer/             # DevContainer feature
│   ├── devcontainer-feature.json    # Feature definition
│   ├── install.sh               # Main installation script
│   ├── presets/                 # Built-in language presets
│   ├── lib/merge-json.js        # JSON merging utility
│   ├── scripts/nodejs-helper.sh # Node.js installation
└── test/claudetainer/           # Automated tests
```

### Data Flow

```
DevContainer startup → install.sh → Preset resolution → File installation → Configuration merging → Claude Code integration
```

1. **Container Creation**: DevContainer CLI starts container with claudetainer feature
2. **Preset Resolution**: Parse `include` parameter, fetch GitHub presets, validate dependencies
3. **File Installation**: Copy commands, hooks, and documentation from presets
4. **Configuration Merging**: Intelligent merge of settings.json files
5. **Finalization**: Set permissions, configure tmux, install Node.js if needed

## Preset Architecture

### Preset Structure

Each preset is a directory containing these standardized files:

```
preset-name/
├── metadata.json       # Preset metadata and dependencies
├── settings.json       # Claude Code hooks and permissions
├── CLAUDE.md           # Preset-specifc instructions for Claude, layered on top of the "base" preset.
├── commands/           # Slash commands (*.md files) that delegate to agents
│   ├── hello.md
│   └── custom-command.md
├── agents/             # Specialized sub-agents
│   ├── code-quality-agent.md
│   ├── commit-specialist.md
│   └── custom-agent.md
└── hooks/              # Executable scripts (for system integration)
    └── custom-hook.sh
```

### File Purposes

| File | Purpose | Merge Strategy |
|------|---------|----------------|
| `metadata.json` | Preset info, dependencies | Not merged |
| `settings.json` | Claude Code configuration | Intelligent deep merge |
| `CLAUDE.md` | Preset-specific Development guidance | Concatenate all presets |
| `commands/*.md` | Slash commands that delegate to agents | Last preset wins |
| `agents/*.md` | Specialized sub-agents | All available (additive) |
| `hooks/*` | Executable scripts (system integration) | Last preset wins |

### Built-in Presets

#### Base Preset
**Purpose**: Universal commands, specialized sub-agents, and foundational workflows

- **Commands**: `/commit`, `/check`, `/next`, `/hello` (delegate to sub-agents)
- **Agents**: Complete quality control and workflow automation suite
- **Hooks**: Basic hello and notification hooks (system integration)
- **Permissions**: Core bash commands (`cat`, `ls`, `echo`, `mkdir`)
- **Best practices**: Research → Plan → Implement workflow with sub-agent coordination

#### Language Presets
Each language preset extends base functionality:

- **Python**: black/flake8/autopep8 pipeline, FastAPI patterns
- **Node.js**: eslint/prettier integration, TypeScript support
- **Go**: gofmt/golangci-lint, module-aware tooling
- **Rust**: rustfmt/clippy integration, Cargo workflows

## Sub-Agent System

The core of claudetainer is the specialized sub-agent system that provides intelligent quality control and workflow automation.

### Sub-Agent Architecture

```
Slash Command → Agent Delegation → Specialized Sub-Agents → Quality Pipeline → Report Results
```

### Quality Control Agents

The base preset includes specialized sub-agents for different aspects of code quality:

**Core Quality Agents:**
- **`code-quality-agent`**: Orchestrator that coordinates the entire quality pipeline
- **`code-formatter`**: Specialized formatting across all languages (black, prettier, gofmt, etc.)
- **`code-linter`**: Comprehensive linting and style checking (eslint, pylint, clippy, etc.)
- **`test-runner`**: Test execution and validation specialist

**Workflow Agents:**
- **`commit-specialist`**: Professional Git commit creation with conventional commit format
- **`project-orchestrator`**: Production-quality implementation with strict standards
- **`development-mentor`**: Guides through research → plan → code → commit workflow

### Agent Coordination

Sub-agents work together through delegation patterns:

```bash
# /check command delegates to code-quality-agent
# code-quality-agent coordinates: formatter → linter → test-runner
# Each specialist reports success/failure with zero tolerance
```

### Integration Points

Sub-agents integrate with Claude Code through:

**Slash Commands:**
- `/check` → `code-quality-agent` (comprehensive quality pipeline)
- `/commit` → `commit-specialist` (professional commit creation)
- `/next` → `development-mentor` + `project-orchestrator` (guided implementation)

**Quality Standards:**
- Zero tolerance for linting violations, formatting issues, or test failures
- Each sub-agent must report complete success before proceeding
- Adaptive coordination handles inter-phase dependencies
- Project-specific tool detection based on configuration

## JSON Merge Logic

The `lib/merge-json.js` utility handles Claude Code-specific merging rules for combining multiple preset configurations.

### Merge Rules

#### Permissions Arrays
```javascript
// Allow/deny arrays are concatenated and deduplicated
"permissions": {
  "allow": ["cat", "ls"] + ["python", "pip"] = ["cat", "ls", "python", "pip"]
}
```

#### Hooks Arrays
```javascript
// Hooks with same matcher are combined, commands deduplicated
[
  { "matcher": "Write", "command": ["lint.sh"] },
  { "matcher": "Write", "command": ["format.sh"] }
]
// Becomes:
{ "matcher": "Write", "command": ["lint.sh", "format.sh"] }
```

#### General Objects
- **Arrays**: Concatenate and deduplicate
- **Objects**: Recursive deep merge
- **Primitives**: Source overwrites target

### Usage

```bash
node lib/merge-json.js target.json source1.json source2.json
```

## Notification System

Claudetainer includes an integrated push notification system using ntfy.sh for real-time development updates.

### Configuration Format

Notifications use JSON configuration files:

```json
{
  "ntfy_topic": "claude-projectname-abc123",
  "ntfy_server": "https://ntfy.sh"
}
```

**Location**: `~/.config/claudetainer/ntfy.json`

### Implementation

- **Auto-generation**: Unique channels created per project using project name + hash
- **Dependencies**: Requires `jq` for JSON parsing and `curl` for HTTP requests
- **Hook Integration**: Triggered by Claude Code events (notification, stop, idle)
- **Rate limiting**: Prevents notification spam (max 1 per 2 seconds)

### Notification Events

- **notification**: General Claude Code notifications (errors get high priority)
- **stop**: Claude finished responding (low priority)
- **idle-notification**: Claude waiting for input >60s (default priority)

## CLI Tool Architecture

The `bin/claudetainer` CLI provides ergonomic devcontainer management with automatic language detection and modular architecture.

### Modular Architecture

**Development Structure**:
```
bin/
├── claudetainer              # Main CLI (143 lines)
├── lib/                     # Core libraries (8 modules)
├── commands/                # Command implementations (7 modules)
└── dist/                   # Built single-file distribution
```

**Build Process**: `./build.sh` creates `dist/claudetainer` (1,435 lines) for distribution

### Command Structure

```bash
claudetainer <command> [options]

Commands:
  init [lang]         # Create .devcontainer with claudetainer feature
  up                  # Start devcontainer
  ssh                 # Connect via SSH with multiplexer session
  doctor              # Comprehensive health check and debugging
  list/ps/ls          # List running containers
```

### Language Detection Logic

```bash
detect_language() {
  if [[ -f "package.json" ]]; then echo "node"
  elif [[ -f "requirements.txt" || -f "pyproject.toml" ]]; then echo "python"
  elif [[ -f "Cargo.toml" ]]; then echo "rust"
  elif [[ -f "go.mod" ]]; then echo "go"
  fi
}
```

### Container Generation

The CLI generates optimized devcontainer.json with:
- **Base image** appropriate for language
- **Features**: Claude Code + claudetainer + SSH + multiplexer (Zellij/tmux)
- **Port forwarding**: Dynamic allocation (2220-2299 range) for SSH access
- **Credential mounting**: `~/.claudetainer-credentials.json`
- **Multiplexer support**: Configurable Zellij layouts (tablet/phone) or tmux

## Multiplexer Architecture

Claudetainer supports multiple terminal multiplexers with configurable layouts and auto-start functionality.

### Supported Multiplexers

| Multiplexer | Description | Key Features |
|-------------|-------------|--------------|
| **Zellij** (default) | Modern terminal workspace | WebAssembly plugins, intuitive UI, configurable layouts |
| **tmux** | Traditional multiplexer | Mature, familiar keybindings, wide compatibility |
| **none** | Simple bash | Minimal setup, no multiplexer overhead |

### Zellij Layout System

**Bundled Layouts**:
- **tablet**: Enhanced 4-tab workflow (claude, cost, git, shell) with GitUI integration
- **phone**: Minimal 4-tab layout optimized for smaller screens

**Layout Features**:
- **GitUI Integration**: Visual git interface with automatic installation to `~/.local/bin/gitui`
- **Usage Monitoring**: Real-time Claude Code usage tracking via ccusage
- **Smart Fallbacks**: Graceful degradation when tools unavailable
- **Layout Switching**: `ct-layout phone|tablet` alias for runtime switching

### Auto-start System

**Configuration**: Scripts at `~/.config/claudetainer/scripts/bashrc-multiplexer.sh`

**Trigger Conditions**:
- SSH connection or VS Code remote session
- Not already inside a multiplexer session
- Valid multiplexer configuration

**Behavior**:
- Auto-navigates to workspace directory
- Creates or attaches to named session (`claudetainer`)
- Provides fallback shell with helpful messages on failure

## GitHub Preset Support

Claudetainer supports remote presets hosted on GitHub repositories.

### Syntax

```bash
INCLUDE="local-preset,github:owner/repo,github:owner/repo/path/to/preset"
```

### Implementation

```bash
# Clone with shallow depth for efficiency
git clone --depth=1 "https://github.com/$owner/$repo.git" "$temp_dir"

# Extract specific path if provided
if [[ -n "$preset_path" ]]; then
  cp -r "$temp_dir/$preset_path" "$presets_dir/github-$repo_name"
else
  cp -r "$temp_dir" "$presets_dir/github-$repo_name"
fi
```

### Error Handling

- **Invalid repository**: Clear error message, continues with other presets
- **Missing path**: Falls back to repository root
- **Network issues**: Graceful degradation, warns user
- **Authentication**: Uses existing git credentials

## Testing Strategy

### Automated Testing

**Primary Methods**:
```bash
# DevContainer CLI testing (primary method)
devcontainer features test .

# CLI Testing (modular + built)
make test-cli

# External CLI lifecycle testing (27 comprehensive tests)
make test-lifecycle

# Test specific scenarios
devcontainer features test --feature claudetainer --base-image mcr.microsoft.com/devcontainers/javascript-node:22-bookworm .
```

**CI/CD Testing**: Three-tier approach
- **test-cli job**: Tests modular and built CLI versions
- **test-scenarios job**: Tests devcontainer features
- **test-cli-lifecycle job**: Tests external CLI functionality

### Test Scenarios

Located in `test/claudetainer/scenarios.json`:

```json
{
  "python-only": { "include": "python" },
  "multi-preset": { "include": "python,node" },
  "github-preset": { "include": "python,github:example/preset" }
}
```

### Manual Testing

```bash
# Quick iteration cycle
export INCLUDE="python,nodejs"
cd /tmp && cp -r /path/to/claudetainer .
./install.sh

# Verify installation
ls ~/.claude/commands/
cat ~/.claude/settings.json | jq .
```

### Validation Checklist

- [ ] Settings.json is valid JSON with expected hooks
- [ ] Commands directory contains expected .md files
- [ ] Hooks directory contains executable scripts
- [ ] CLAUDE.md exists and contains preset documentation
- [ ] Smart-lint works for target language
- [ ] SSH access works on dynamically allocated port
- [ ] Multiplexer integration functions properly (Zellij/tmux)
- [ ] Notification system configured with ntfy.json
- [ ] GitUI installed and accessible
- [ ] Layout switching alias (`ct-layout`) works

## CI/CD Integration

### GitHub Actions Workflows

#### Test Workflow (`.github/workflows/test.yaml`)
- Runs on every PR
- Tests claudetainer feature with Node.js 18 base image
- Validates all test scenarios automatically
- Matrix testing for different preset combinations

#### Release Workflow (`.github/workflows/release.yaml`)
- Triggered on version tags
- Publishes feature to GitHub Container Registry
- Auto-generates documentation
- Creates update PRs

### Publishing Process

Features are published to `ghcr.io/smithclay/claudetainer` using the DevContainer publishing action:

```yaml
- uses: devcontainers/action@v1
  with:
    publish-features: "true"
    base-path-to-features: "./src"
```

## Creating Custom Presets

### Preset Development Workflow

1. **Create preset directory**:
   ```bash
   mkdir -p my-preset/{commands,agents,hooks}
   ```

2. **Define metadata** (`metadata.json`):
   ```json
   {
     "name": "my-preset",
     "description": "Custom development preset",
     "dependencies": ["base"]
   }
   ```

3. **Configure Claude Code** (`settings.json`):
   ```json
   {
     "permissions": {
       "allow": ["my-tool", "custom-command"]
     },
     "hooks": [
       {
         "type": "PostToolUse",
         "matcher": "Write",
         "command": ["~/.claude/hooks/my-hook.sh", "$FILE_PATH"]
       }
     ]
   }
   ```

4. **Add commands** (`commands/my-command.md`):
   ```markdown
   # My Custom Command

   Description of what this slash command does.

   Usage: /my-command
   ```

5. **Create hooks** (`hooks/my-hook.sh`):
   ```bash
   #!/bin/bash
   # Custom hook implementation
   echo "Processing $1"
   ```

6. **Document usage** (`CLAUDE.md`):
   ```markdown
   # My Preset

   This preset provides custom functionality for...
   ```

### Testing Custom Presets

```bash
# Local testing
export INCLUDE="base,/path/to/my-preset"
./install.sh

# GitHub testing
export INCLUDE="base,github:myorg/my-preset"
./install.sh
```

### Distribution

Host your preset on GitHub and reference it:

```json
{
  "features": {
    "claudetainer": {
      "include": "base,github:myorg/my-preset"
    }
  }
}
```

## Development Environment Setup

### Prerequisites

- **Node.js 16+** - For JSON merging utilities
- **Bash 4.0+** - For installation scripts
- **Git** - For GitHub preset support
- **Docker** - For devcontainer testing
- **DevContainer CLI** - `npm install -g @devcontainers/cli`

### Local Development

```bash
# Clone repository
git clone https://github.com/smithclay/claudetainer.git
cd claudetainer

# Test locally
devcontainer features test .

# Test specific scenario
export INCLUDE="python,node"
cd src/claudetainer && ./install.sh
```

## Contributing

### Code Standards

- **Bash**: Follow shellcheck recommendations
- **JSON**: Use proper indentation and validation
- **Markdown**: Follow consistent formatting
- **Error handling**: Provide clear, actionable error messages

### Pull Request Process

1. **Fork and branch**: Create feature branch from main
2. **Test thoroughly**: Run full test suite locally
3. **Update documentation**: Modify relevant docs
4. **Submit PR**: Include clear description and test evidence
5. **Address feedback**: Respond to review comments
6. **Squash and merge**: Maintain clean commit history

### Review Criteria

- [ ] All automated tests pass
- [ ] Code follows existing patterns and standards
- [ ] Documentation is updated appropriately
- [ ] Backwards compatibility is maintained
- [ ] Error handling is comprehensive
- [ ] Performance impact is minimal

## Troubleshooting

### Common Issues

#### Installation Fails
```bash
# Check Node.js availability
node --version || echo "Node.js required"

# Verify permissions
ls -la ~/.claude/

# Check disk space
df -h
```

#### Preset Not Found
```bash
# Local preset path
ls -la /path/to/preset/

# GitHub preset
git ls-remote https://github.com/owner/repo.git
```

#### Hook Execution Fails
```bash
# Check executable permissions
ls -la ~/.claude/hooks/

# Test quality control via sub-agents
# Use /check command in Claude Code to trigger quality agents

# Check dependencies
which black flake8 autopep8
```

#### SSH Connection Issues
```bash
# Verify container is running
docker ps | grep devcontainer

# Check port forwarding
nc -z localhost 2223

# SSH debug mode
ssh -vvv -p 2223 vscode@localhost
```

### Debug Mode

Enable verbose logging:

```bash
export DEBUG=1
./install.sh
```

### Getting Help

- **Issues**: https://github.com/smithclay/claudetainer/issues
- **Discussions**: https://github.com/smithclay/claudetainer/discussions
- **Claude Code Community**: https://claude.ai/code

## Performance Considerations

### Installation Optimization

- **Shallow clones**: `git clone --depth=1` for GitHub presets
- **Minimal dependencies**: Only install required tools
- **Efficient merging**: Single-pass JSON processing
- **Parallel operations**: Where possible, run tasks concurrently

### Runtime Performance

- **Hook efficiency**: Fast execution for common operations
- **Tool availability checks**: Cache results when possible
- **File filtering**: Exclude irrelevant files from processing
- **Graceful degradation**: Continue working when optional tools missing

## Security Considerations

### Preset Security

- **Code review**: All built-in presets are reviewed
- **GitHub presets**: Users responsible for trusting sources
- **Execution permissions**: Hooks run with container user permissions
- **Input validation**: Sanitize user-provided preset names and paths

### Container Security

- **Credential mounting**: Optional, user-controlled
- **SSH access**: Password authentication, container-scoped
- **Network isolation**: Standard devcontainer security model
- **File permissions**: Appropriate ownership and access controls

---

For questions about this guide or contributing to claudetainer, please open an issue or discussion on GitHub.
