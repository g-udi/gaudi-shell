# shellcheck shell=bash

cite about-alias
about-alias 'Ruby Rails aliases'

alias r='rails'
# rg (ripgrep), ss and ts are real tools: alias them only when no such binary is installed
hash rg 2> /dev/null || alias rg='rails g'
alias rgen='rails g'
alias rs='rails s'
alias rc='rails c'
alias rn='rails new'
alias rb='rails dbconsole'
alias rp='rails plugin'
alias ra='rails application'
alias rdes='rails destroy'
alias dbm='rake db:migrate'
hash ss 2> /dev/null || alias ss='script/server'
hash ts 2> /dev/null || alias ts="thin start"
alias rsc='script/console'
alias restartapp='touch tmp/restart.txt'
alias restart='touch tmp/restart.txt'
alias devlog='tail -f log/development.log'
alias taild='tail -f log/development.log'
