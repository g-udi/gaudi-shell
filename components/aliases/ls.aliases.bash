# shellcheck shell=bash

cite about-alias
about-alias 'ls aliases to add coloring and extra arguments'

# ls: always use color output
# ll: list all files colorized in long format
# la: the same, including dot files
# lsd: list only directories
# llt: long format, newest first
if command ls --version &> /dev/null; then
  # GNU ls
  alias ls='command ls --color=auto'
  alias ll='ls -lF'
  alias la='ls -laF'
  alias lsd="ls -lF | grep --color=never '^d'"
  alias llt='ls -lFt'
elif command ls -G -d . &> /dev/null; then
  # BSD ls (macOS): -G colors the output
  alias ls="command ls -G"
  alias ll="ls -lFG"
  alias la="ls -laFG"
  alias lsd="ls -lFG | grep --color=never '^d'"
  alias llt="ls -lFtG"
else
  alias ls='command ls'
  alias ll='ls -lF'
  alias la='ls -laF'
  alias lsd="ls -lF | grep '^d'"
  alias llt='ls -lFt'
fi

alias l='ls -a'
alias l1='ls -1'
