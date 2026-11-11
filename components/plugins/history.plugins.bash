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
  about 'Syncs the history with the history file, then runs the history builtin'
  group 'history'

  _bash_history_sync
  builtin history "$@"
}

# Save and reload the history after each command finishes.
# Add the hook once and keep whatever is already in PROMPT_COMMAND (string or array)
if [[ "${PROMPT_COMMAND[*]:-}" != *"_bash_history_sync"* ]]; then
  if [[ "$(declare -p PROMPT_COMMAND 2> /dev/null)" == "declare -a"* ]]; then
    PROMPT_COMMAND=(_bash_history_sync "${PROMPT_COMMAND[@]}")
  elif [[ -n "${PROMPT_COMMAND:-}" ]]; then
    PROMPT_COMMAND="_bash_history_sync; ${PROMPT_COMMAND}"
  else
    PROMPT_COMMAND="_bash_history_sync"
  fi
fi
