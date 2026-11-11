
# shellcheck shell=bash

cite about-completion
about-completion 'Docker bash completions'

# Make sure docker is installed
_command_exists docker || return 0

# Don't handle completion if it's already managed
complete -p docker &>/dev/null && return 0

_docker_bash_completion_paths=(
  # MacOS
  '/Applications/Docker.app/Contents/Resources/etc/docker.bash-completion'
  # Linux
  '/usr/share/bash-completion/completions/docker'
)

for fn in "${_docker_bash_completion_paths[@]}" ; do
  if [[ -r "$fn" ]] ; then
    # shellcheck source=/dev/null
    source "$fn"
    break
  fi
done
