# shellcheck shell=bash
cite about-completion
about-completion "yarn cli completions"

_command_exists yarn || return

complete -p yarn &> /dev/null && return

# Yarn 1.x doesn't have a built-in completion command, provide basic completions
_yarn_completion() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local prev="${COMP_WORDS[COMP_CWORD-1]}"

	local commands="add audit autoclean bin cache check config create generate-lock-entry global help import info init install licenses link list login logout node outdated owner pack policies publish remove run tag team test unlink unplug upgrade upgrade-interactive version versions why workspace workspaces"

	if [[ ${COMP_CWORD} -eq 1 ]]; then
		COMPREPLY=($(compgen -W "${commands}" -- "${cur}"))
	fi
}

complete -F _yarn_completion yarn
