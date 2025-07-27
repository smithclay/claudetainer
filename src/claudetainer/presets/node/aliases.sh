#!/bin/bash
# Node.js aliases for improved development workflow

# Package manager shortcuts
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias nu='npm uninstall'
alias nug='npm uninstall -g'
alias nup='npm update'

# Script execution shortcuts
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'
alias nd='npm run dev'
alias nl='npm run lint'
alias nf='npm run format'

# Package information
alias nls='npm list'
alias nlsg='npm list -g --depth=0'
alias nout='npm outdated'
alias nv='npm version'

# Yarn shortcuts (if yarn is available)
if command -v yarn &> /dev/null; then
    alias y='yarn'
    alias ya='yarn add'
    alias yad='yarn add --dev'
    alias yr='yarn remove'
    alias yu='yarn upgrade'
    alias yi='yarn install'
    alias ys='yarn start'
    alias yt='yarn test'
    alias yb='yarn build'
    alias yd='yarn dev'
    alias yl='yarn lint'
    alias yf='yarn format'
fi

echo "📦 Node.js aliases loaded"
