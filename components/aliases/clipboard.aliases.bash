# shellcheck shell=bash

cite about-alias
about-alias 'pbcopy and pbpaste shortcuts to linux'

case $OSTYPE in
  linux*)
    if command -v xclip > /dev/null 2>&1; then
      pbcopy () { command xclip -selection clipboard "$@"; }
      pbpaste () { command xclip -selection clipboard -o "$@"; }
    fi
    ;;
esac
