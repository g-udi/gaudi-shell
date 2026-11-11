# shellcheck shell=bash
# shellcheck disable=SC2155,SC2207

cite about-completion
about-completion 'Ngrok bash completions'

_binary_exists ngrok || return 0

# Don't handle completion if it's already managed
complete -p ngrok &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_ngrok() {
  local spec
  spec="$(complete -p ngrok 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r ngrok
    eval "$(SHELL=bash ngrok completion 2> /dev/null)"
    spec="$(complete -p ngrok 2> /dev/null)"
    # Completing ngrok itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == ngrok && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of ngrok: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_ngrok ngrok
