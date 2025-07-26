#!/bin/bash
# Go aliases for improved development workflow

# Basic Go commands
alias gob='go build'
alias gor='go run'
alias got='go test'
alias goi='go install'
alias goc='go clean'
alias gof='go fmt'
alias gov='go vet'
alias god='go doc'

# Module management
alias gom='go mod'
alias gomi='go mod init'
alias gomt='go mod tidy'
alias gomv='go mod verify'
alias gomd='go mod download'
alias goms='go mod sum'

echo "🐹 Go aliases loaded"
