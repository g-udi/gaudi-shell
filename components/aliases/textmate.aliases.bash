# shellcheck shell=bash

cite about-alias
about-alias 'textmate aliases'

case $OSTYPE in
  darwin*)
    alias e='mate . &'
    ;;
esac
