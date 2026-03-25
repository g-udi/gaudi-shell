# shellcheck shell=bash

cite about-plugin
about-plugin 'history manipulation'

_bash_history_sync () {
  builtin history -a         
  HISTFILESIZE=$HISTSIZE     
  builtin history -c         
  builtin history -r         
}

history () {
  _bash_history_sync
  builtin history "$@"
}

PROMPT_COMMAND=_bash_history_sync

# Save and reload the history after each command finishes
export PROMPT_COMMAND="_bash_history_sync; $PROMPT_COMMAND"
