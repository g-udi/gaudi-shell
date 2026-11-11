# shellcheck shell=bash

cite about-alias
about-alias 'vim abbreviations'

# Private names: VIM is vim's own runtime-directory variable
_gaudi_vim=$(command -v vim)
_gaudi_gvim=$(command -v gvim)
_gaudi_mvim=$(command -v mvim)

[[ -n $_gaudi_vim ]] && alias v="command vim"

# open vim in new tab is taken from http://stackoverflow.com/questions/936501/let-gvim-always-run-a-single-instancek
case $OSTYPE in
  darwin*)
	[[ -n $_gaudi_mvim ]] && mvimt () { command mvim --remote-tab-silent "$@" || command mvim "$@"; }
    ;;
  *)
    [[ -n $_gaudi_gvim ]] && gvimt () { command gvim --remote-tab-silent "$@" || command gvim "$@"; }
    ;;
esac
unset _gaudi_vim _gaudi_gvim _gaudi_mvim
