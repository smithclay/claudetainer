#!/bin/bash
# Rust aliases for improved development workflow

# Basic Cargo commands
alias cb='cargo build'
alias cr='cargo run'
alias ct='cargo test'
alias cc='cargo check'
alias cf='cargo fmt'
alias cl='cargo clippy'
alias cd='cargo doc'
alias cn='cargo new'
alias ci='cargo init'

# Release builds
alias cbr='cargo build --release'
alias crr='cargo run --release'
alias ctr='cargo test --release'

# Testing shortcuts
alias ctest='cargo test'
alias ctestv='cargo test -- --nocapture'
alias ctests='cargo test --all'
alias ctestdoc='cargo test --doc'
alias ctestint='cargo test --test'

# Development tools
alias cformat='cargo fmt'
alias ccheck='cargo check --all'
alias cclippy='cargo clippy'
alias cclippyfix='cargo clippy --fix'
alias cclippyall='cargo clippy --all-targets --all-features'

# Documentation
alias cdoc='cargo doc'
alias cdocopen='cargo doc --open'
alias cdocno='cargo doc --no-deps'

# Package management
alias cadd='cargo add'
alias cremove='cargo remove'
alias cupdate='cargo update'
alias csearch='cargo search'
alias cinstall='cargo install'
alias cuninstall='cargo uninstall'

echo "🦀 Rust aliases loaded"
