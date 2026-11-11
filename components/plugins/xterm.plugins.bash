# shellcheck shell=bash
cite about-plugin
about-plugin 'Automatically set your xterm title with host and location info'


_short-dirname () {
  local dir_name

  dir_name=$(dirs +0)
  [[ "$SHORT_TERM_LINE" = true ]] && [[ ${#dir_name} -gt 8 ]] && echo "${dir_name##*/}" || echo "$dir_name"
}

_short-command () {
  local input_command="$*"
  [[ "$SHORT_TERM_LINE" = true ]] && [[ ${#input_command} -gt 8 ]] && echo "${input_command%% *}" || echo "$input_command"
}

set_xterm_title () {
    about 'Sets the xterm window title'
    param '1: title'
    group 'xterm'

    local title="$1"
    echo -ne "\033]0;$title\007"
}

precmd () {
    about 'Sets the xterm title to user@host and the directory before each prompt'
    group 'xterm'

    set_xterm_title "${SHORT_USER:-${USER}}@${SHORT_HOSTNAME:-${HOSTNAME}} $(_short-dirname) $PROMPTCHAR"
}

preexec () {
    about 'Sets the xterm title to the command being run'
    group 'xterm'

    set_xterm_title "$(_short-command "$1") {$(_short-dirname)} (${SHORT_USER:-${USER}}@${SHORT_HOSTNAME:-${HOSTNAME}})"
}
