# shellcheck shell=bash

cite about-alias
about-alias 'General aliases for navigation and common tasks'

# sudo powers
alias _="sudo"

# count items
alias count='ls -1 | grep -c "^.*$"'

# colored grep
# Only when this grep supports the color option
if echo a | grep --color=auto a &> /dev/null; then
  alias grep='grep --color=auto'
fi

# clear screen alias à la Linux
alias cls="clear"

# navigation aliases
alias ..="cd .."
alias cd..='cd ..'
alias ...="cd ../.."
alias ....="cd ../../.."
alias -- -='cd -'
alias ~="cd ~"

# directory creation and removal
alias md="mkdir -p"
alias rd="rmdir"

# shell History
alias h="history"

# print PATH, one directory per line
alias path='echo $PATH | tr : \\n'

# tree (list directories as a tree structure)
if ! command -v tree > /dev/null 2>&1; then
  alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
fi

# Shortcuts to edit startup files
alias vbrc="vim ~/.bashrc"
alias vbpf="vim ~/.bash_profile"
