#!/bin/bash
# Base aliases for all claudetainer environments

# Claude Code shortcuts
alias claude='claude'
alias c='claude'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gl='git log --oneline'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gm='git merge'
alias gr='git rebase'
alias gf='git fetch'
alias glog='git log --graph --pretty=format:"%h -%d %s (%cr) <%an>" --abbrev-commit'

# GitUI shortcut (if available)
if command -v gitui &> /dev/null; then
    alias gu='gitui'
fi

# Directory navigation
alias ll='ls -la'
alias la='ls -la'
alias l='ls -l'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# File operations
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias mkdir='mkdir -p'

# Search shortcuts
if command -v rg &> /dev/null; then
    alias grep='rg'
    alias search='rg'
else
    alias grep='grep --color=auto'
fi

if command -v fd &> /dev/null; then
    alias find='fd'
fi

# Tree command with good defaults
if command -v tree &> /dev/null; then
    alias tree='tree -I "node_modules|.git|__pycache__|.pytest_cache|.mypy_cache|.ruff_cache|target|vendor"'
fi

# Editor shortcuts
alias v='vim'
alias e='$EDITOR'

# Process shortcuts
alias psg='ps aux | grep'
alias k='kill'
alias k9='kill -9'

# Archive shortcuts
alias tgz='tar -czf'
alias tgzx='tar -xzf'

echo "🔧 Base aliases loaded"
