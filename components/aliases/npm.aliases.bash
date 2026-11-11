# shellcheck shell=bash

cite about-alias
about-alias 'Common npm abbreviations'

# ni and nx are real tools (antfu/ni, Nx): alias them only when no such binary is installed
hash ni 2> /dev/null || alias ni='npm install'
alias nis='npm install --save-prod'
alias nid='npm install --save-dev'
alias nit='npm install-test'
alias nits='npm install-test --save-prod'
alias nitd='npm install-test --save-dev'
alias nu='npm uninstall'
alias nus='npm uninstall'
alias nusd='npm uninstall --save-dev'
alias np='npm publish'
alias nup='npm unpublish'
alias nlk='npm link'
alias nod='npm outdated'
alias nrb='npm rebuild'
alias nud='npm update'
alias nr='npm run'
alias nls='npm list --depth=0 2>/dev/null'
alias nlsg='npm list -g --depth=0 2>/dev/null'
hash nx 2> /dev/null || alias nx='npx'
alias nxplease='npx $(fc -ln -1)'
# npm 7+ npx: --no replaces --no-install, --ignore-existing is gone
alias nxn='npx --no '
alias nxp='npx -p '
alias nxnp='npx --no -p '
alias nxq='npx -q '
alias nxnq='npx --no -q '
alias nxqp='npx -q -p '
alias nxnqp='npx --no -q -p '
