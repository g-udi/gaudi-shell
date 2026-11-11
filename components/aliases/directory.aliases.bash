# shellcheck shell=bash
cite about-alias
about-alias 'Shortcuts for directory commands: ls, cd, &c.'

# The ls family (ls, ll, la, l, l1) is owned by the "ls" aliases, or by the
# "gls" aliases when GNU ls is installed: only define it here when neither is enabled.
_gaudi_ls_owner="directory"
for _gaudi_ls_file in "${GAUDI_SHELL:-}"/components/enabled/*___ls.aliases.bash; do
	[[ -e "$_gaudi_ls_file" ]] && _gaudi_ls_owner="ls"
done
if hash gls 2> /dev/null; then
	for _gaudi_ls_file in "${GAUDI_SHELL:-}"/components/enabled/*___gls.aliases.bash; do
		[[ -e "$_gaudi_ls_file" ]] && _gaudi_ls_owner="gls"
	done
fi

if [[ "$_gaudi_ls_owner" == directory ]]; then
	if command ls --color -d . &> /dev/null; then
		alias ls='ls --color=auto'
		# BSD `ls` doesn't need an argument (`-G`) when `$CLICOLOR` is set.
	fi
	alias la='ls -AF' # Compact view, show hidden
	alias ll='ls -Al'
	alias l='ls -A'
	alias l1='ls -1'
fi
unset _gaudi_ls_owner _gaudi_ls_file

# List directory contents
alias sl=ls
alias lf='ls -F'

# Change directory
alias ..='cd ..'         # Go up one directory
alias cd..='cd ..'       # Common misspelling for going up one directory
alias ...='cd ../..'     # Go up two directories
alias ....='cd ../../..' # Go up three directories
alias -- -='cd -'        # Go back

# Create or remove directory
alias md='mkdir -p'
alias rd='rmdir'
