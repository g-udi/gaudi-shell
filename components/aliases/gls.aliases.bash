# shellcheck shell=bash

cite about-alias
about-alias 'gls enhanced ls (port from Linux using coreutils)'

# The ls family (ls, ll, la, l, l1, lsd) is owned by the "ls" aliases. GNU ls
# only takes it over when it is the active choice: coreutils is installed and
# the "ls" aliases are not enabled.
_gaudi_ls_owner="gls"
for _gaudi_ls_file in "${GAUDI_SHELL:-}"/components/enabled/*___ls.aliases.bash; do
  [[ -e "$_gaudi_ls_file" ]] && _gaudi_ls_owner="ls"
done

if [[ "$_gaudi_ls_owner" == gls ]] && _binary_exists gls; then
  # List all files colorized in long format
  alias ll="gls -lFX --color"
  # List all files colorized in long format, including dot files
  alias la="gls --color -lXAhF --ignore={.DS_Store,.git}"
  # List only directories
  alias lsd="gls -lF --color | grep --color=never '^d'"
  # Always use color output for `ls`
  alias ls="command gls --color"
  alias l='gls -aX'
  alias l1='gls -1X'
fi
unset _gaudi_ls_owner _gaudi_ls_file
