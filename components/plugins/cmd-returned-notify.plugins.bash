# shellcheck shell=bash
cite about-plugin
about-plugin 'Alert (BEL) when a command takes longer than a threshold to complete'

# Threshold in seconds (default: 5)
: "${NOTIFY_IF_COMMAND_RETURNS_AFTER:=5}"

__cmd_notify_preexec() {
	__CMD_NOTIFY_START=${EPOCHREALTIME:-$SECONDS}
}

__cmd_notify_precmd() {
	local now=${EPOCHREALTIME:-$SECONDS}
	local -i duration="$((${now%.*} - ${__CMD_NOTIFY_START%.*:-0}))"
	if [[ "${duration}" -gt "${NOTIFY_IF_COMMAND_RETURNS_AFTER}" ]]; then
		printf '\a'
	fi
}

trap '__cmd_notify_preexec' DEBUG
PROMPT_COMMAND="__cmd_notify_precmd;${PROMPT_COMMAND}"
