# shellcheck shell=bash
# shellcheck disable=SC1090

cite about-plugin
about-plugin 'Loads Git Submodule Alternative via git-subrepo and initialize completions'

if [[ -e "${GIT_SUBREPO_ROOT:=$HOME/.git-subrepo}/init" ]]; then
  # shellcheck source=/dev/null
  source "$GIT_SUBREPO_ROOT/init"
fi
