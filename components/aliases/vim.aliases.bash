# shellcheck shell=bash

cite about-alias
about-alias 'vim abbreviations'

# Private names: VIM is vim's own runtime-directory variable
_gaudi_vim=$(command -v vim || true)
_gaudi_gvim=$(command -v gvim || true)
_gaudi_mvim=$(command -v mvim || true)

if [[ -n $_gaudi_vim ]]; then
  alias v="command vim"
fi

# open vim in new tab is taken from http://stackoverflow.com/questions/936501/let-gvim-always-run-a-single-instancek
case $OSTYPE in
  darwin*)
    if [[ -n $_gaudi_mvim ]]; then
      mvimt () { command mvim --remote-tab-silent "$@" || command mvim "$@"; }
    fi
    ;;
  *)
    if [[ -n $_gaudi_gvim ]]; then
      gvimt () { command gvim --remote-tab-silent "$@" || command gvim "$@"; }
    fi
    ;;
esac
unset _gaudi_vim _gaudi_gvim _gaudi_mvim
