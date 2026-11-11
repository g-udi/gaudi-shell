# shellcheck shell=bash

cite about-completion
about-completion 'Docker compose bash completions'

# "docker compose" (the CLI plugin) is completed by the docker completion. This
# covers the standalone docker-compose v2 binary, which prints its own script.
_binary_exists docker-compose || return 0

# Don't handle completion if it's already managed
complete -p docker-compose &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_docker_compose() {
  local spec
  spec="$(complete -p docker-compose 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r docker-compose
    eval "$(docker-compose completion bash 2> /dev/null)"
    spec="$(complete -p docker-compose 2> /dev/null)"
    # Completing docker-compose itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == docker-compose && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of docker-compose: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_docker_compose docker-compose
