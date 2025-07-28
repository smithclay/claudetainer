
# claudetainer (claudetainer)

Opinionated Claude Code workflows via preconfigured hooks and commands

## Example Usage

```json
"features": {
    "ghcr.io/smithclay/claudetainer/claudetainer:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| include | Comma-separated list of presets to include (python, nodejs, go, shell, etc.) | string | - |
| includeBase | Include universal commands and hooks | boolean | true |
| multiplexer | Shell multiplexer for remote sessions (zellij=modern, tmux=traditional, none=simple) | string | zellij |
| zellij_layout | Zellij layout to use: bundled layouts (tablet, phone) or custom path (/path/to/layout.kdl) | string | phone |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/smithclay/claudetainer/blob/main/src/claudetainer/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
