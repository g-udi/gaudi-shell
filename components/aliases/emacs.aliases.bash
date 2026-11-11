# shellcheck shell=bash

cite about-alias
about-alias 'Emacs editor'

case $OSTYPE in
  linux*)
    alias em='emacs'
    alias en='emacs -nw'
    alias e='emacsclient -n'
    alias et='emacsclient -t'
    # ed is a real editor: alias it only when no such binary is installed
    hash ed 2> /dev/null || alias ed='emacs --daemon'
    alias emd='emacs --daemon'
    alias E='SUDO_EDITOR=emacsclient sudo -e'
    ;;
  darwin*)
    alias em='open -a emacs'
    ;;
esac
