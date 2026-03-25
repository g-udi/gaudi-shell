# shellcheck shell=bash

cite about-plugin
about-plugin 'Load chruby (from /usr/local/share/chruby)'

[ -f /usr/local/share/chruby/chruby.sh ] && source /usr/local/share/chruby/chruby.sh
[ -f /usr/local/share/chruby/auto.sh ] && source source /usr/local/share/chruby/auto.sh

