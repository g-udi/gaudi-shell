# shellcheck shell=bash
cite about-plugin
about-plugin 'load fasd, if you are using it'

_command_exists fasd || return 0

eval "$(fasd --init auto)"
