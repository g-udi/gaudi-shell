# shellcheck shell=bash
cite about-plugin
about-plugin 'Alert (BEL) when a command takes longer than a threshold to complete'

# Threshold in seconds (default: 5)
: "${NOTIFY_IF_COMMAND_RETURNS_AFTER:=5}"

[[ $- == *i* ]] || return 0

__cmd_notify_preexec() {
	__CMD_NOTIFY_START=${SECONDS}
}

__cmd_notify_precmd() {
	local start=${__CMD_NOTIFY_START:-}
	__CMD_NOTIFY_START=""
	# no command ran since the last prompt
	[[ -n "${start}" ]] || return 0
	local -i duration=$((SECONDS - start))
	if [[ "${duration}" -gt "${NOTIFY_IF_COMMAND_RETURNS_AFTER}" ]]; then
		printf '\a'
	fi
}

if [[ -n "${ZSH_VERSION:-}" ]] || type -t __bp_precmd_invoke_cmd &> /dev/null; then
	# zsh and bash-preexec run the preexec/precmd function arrays themselves
	if [[ " ${preexec_functions[*]:-} " != *" __cmd_notify_preexec "* ]]; then
		preexec_functions+=(__cmd_notify_preexec)
	fi
	if [[ " ${precmd_functions[*]:-} " != *" __cmd_notify_precmd "* ]]; then
		precmd_functions+=(__cmd_notify_precmd)
	fi
else
	# Plain bash: PS0 (bash 4.4+) is expanded right before a command runs, so
	# its arithmetic records the start time in the current shell. The DEBUG
	# trap is left alone, as another hook may own it.
	__CMD_NOTIFY_PS0=""
	if [[ "${PS0:-}" != *"__CMD_NOTIFY_START"* ]]; then
		# shellcheck disable=SC2016 # expanded by the shell each time PS0 is printed
		PS0="${PS0:-}"'${__CMD_NOTIFY_PS0:0:$((__CMD_NOTIFY_START=SECONDS,0))}'
	fi

	if [[ "${PROMPT_COMMAND[*]:-}" != *"__cmd_notify_precmd"* ]]; then
		if [[ "$(declare -p PROMPT_COMMAND 2> /dev/null)" == "declare -a"* ]]; then
			PROMPT_COMMAND=(__cmd_notify_precmd "${PROMPT_COMMAND[@]}")
		elif [[ -n "${PROMPT_COMMAND:-}" ]]; then
			PROMPT_COMMAND="__cmd_notify_precmd;${PROMPT_COMMAND}"
		else
			PROMPT_COMMAND="__cmd_notify_precmd"
		fi
	fi
fi
