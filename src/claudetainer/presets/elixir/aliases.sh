#!/bin/bash
# Elixir aliases for improved development workflow

# Basic Mix commands
alias mxc='mix compile'
alias mxr='mix run'
alias mxt='mix test'
alias mxf='mix format'
alias mxd='mix deps.get'
alias mxn='mix new'

# Development tools
alias mxcredo='mix credo'
alias mxdialyzer='mix dialyzer'
alias mxcheck='mix compile && mix credo && mix dialyzer'

# Testing shortcuts
alias mxtest='mix test'
alias mxtestv='mix test --trace'
alias mxtestw='mix test.watch'
alias mxtests='mix test --stale'
alias mxtestf='mix test --failed'

# Documentation
alias mxdoc='mix docs'
alias mxdocopen='mix docs && open doc/index.html'

# IEx (Interactive Elixir)
alias iex='iex -S mix'
alias iexs='iex -S mix'
alias iext='iex -S mix test'

# Phoenix shortcuts (if Phoenix is available)
if grep -q "phoenix" mix.exs 2>/dev/null; then
    alias mxs='mix phx.server'
    alias mxg='mix phx.gen'
    alias mxroutes='mix phx.routes'
    alias mxmigrate='mix ecto.migrate'
    alias mxrollback='mix ecto.rollback'
    alias mxseed='mix run priv/repo/seeds.exs'
fi

echo "💧 Elixir aliases loaded"
