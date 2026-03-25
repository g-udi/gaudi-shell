# shellcheck shell=bash
# shellcheck disable=SC1090

cite about-plugin
about-plugin 'Loads Git Submodule Alternative via git-subrepo and initialize completions'

[[ -e "${GIT_SUBREPO_ROOT:=~/.git-subrepo}/init" ]] && source "$GIT_SUBREPO_ROOT/init"
