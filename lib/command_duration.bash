#!/usr/bin/env bash
# shellcheck shell=bash
#
# Command execution duration tracking.
# Uses EPOCHREALTIME for sub-second precision (bash 5 and zsh), falls back to
# $SECONDS (whole seconds) in older bash.

# zsh only has EPOCHREALTIME once this module is loaded
if [[ -n "${ZSH_VERSION:-}" ]]; then
	zmodload zsh/datetime 2>/dev/null
fi

_command_duration_current_time() {
	local current_time fraction
	if [[ -n "${EPOCHREALTIME:-}" ]]; then
		current_time="${EPOCHREALTIME//[!0-9]/.}"
		# Exactly six decimals (microseconds): zsh prints more than bash does
		fraction="${current_time#*.}000000"
		current_time="${current_time%%.*}.${fraction:0:6}"
	else
		current_time="$SECONDS"
	fi
	echo "$current_time"
}

# Empty until a command is started from the prompt, so the first prompt of a
# shell shows nothing (it used to show how long the shell took to start).
COMMAND_DURATION_START_SECONDS=""
: "${COMMAND_DURATION_MIN_SECONDS:=1}"
: "${COMMAND_DURATION_PRECISION:=1}"

# Runs right before a command typed at the prompt: start the timer.
_command_duration_pre_exec() {
	[[ -n "${GAUDI_SHELL_COMMAND_DURATION:-}" ]] || return 0
	COMMAND_DURATION_START_SECONDS="$(_command_duration_current_time)"
}

# Runs after the prompt has been drawn: reset the timer, so the next prompt
# only shows a duration if a command ran in between.
_command_duration_pre_cmd() {
	COMMAND_DURATION_START_SECONDS=""
	_COMMAND_DURATION_AT_PROMPT=1
}

# True when "$1" is, as a whole, one of the commands in PROMPT_COMMAND (which
# may be an array, and whose entries may hold several commands separated by
# ";" or newlines). Whole commands are compared: a substring test would also
# hide short commands such as ":" or "history" typed at the prompt.
_command_duration_is_prompt_command() {
	local _entry _rest _command
	[[ -n "$1" ]] || return 1
	for _entry in "${PROMPT_COMMAND[@]:-}"; do
		_rest="${_entry//$'\n'/;}"
		while [[ -n "$_rest" ]]; do
			_command="${_rest%%;*}"
			if [[ "$_rest" == *";"* ]]; then
				_rest="${_rest#*;}"
			else
				_rest=""
			fi
			# Trim the blanks around the command
			_command="${_command#"${_command%%[![:space:]]*}"}"
			_command="${_command%"${_command##*[![:space:]]}"}"
			[[ "$_command" == "$1" ]] && return 0
		done
	done
	return 1
}

# bash DEBUG trap, used when bash-preexec is not loaded. It fires before every
# top-level command; only the first one after a prompt starts the timer, and
# commands that belong to PROMPT_COMMAND are ignored. "$1" is the previous
# "$_", passed through so the trap leaves it unchanged.
_command_duration_debug_trap() {
	if [[ -n "${_COMMAND_DURATION_AT_PROMPT:-}" && -z "${COMP_LINE:-}" ]] &&
		! _command_duration_is_prompt_command "${BASH_COMMAND:-}"; then
		_COMMAND_DURATION_AT_PROMPT=""
		_command_duration_pre_exec
	fi
	: "${1:-}"
}

# Hook the reset (and, where the shell has them, the preexec/precmd arrays).
# Runs as a finalize hook, after the theme has registered its prompt function,
# so the reset happens after the prompt was rendered.
_command_duration_register_hooks() {
	[[ $- == *i* ]] || return 0

	if [[ " ${preexec_functions[*]:-} " != *" _command_duration_pre_exec "* ]]; then
		preexec_functions+=(_command_duration_pre_exec)
	fi

	# zsh runs precmd_functions natively; in bash only bash-preexec does.
	if [[ -n "${ZSH_VERSION:-}" ]] || type -t __bp_precmd_invoke_cmd &>/dev/null; then
		if [[ " ${precmd_functions[*]:-} " != *" _command_duration_pre_cmd "* ]]; then
			precmd_functions+=(_command_duration_pre_cmd)
		fi
		return 0
	fi

	[[ "${PROMPT_COMMAND[*]:-}" == *"_command_duration_pre_cmd"* ]] && return 0
	if [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" == "declare -a"* ]]; then
		PROMPT_COMMAND+=(_command_duration_pre_cmd)
	elif [[ -n "${PROMPT_COMMAND:-}" ]]; then
		PROMPT_COMMAND="${PROMPT_COMMAND%;}"$'\n'"_command_duration_pre_cmd"
	else
		PROMPT_COMMAND="_command_duration_pre_cmd"
	fi
}

GAUDI_SHELL_FINALIZE_HOOKS+=(_command_duration_register_hooks)

# Plain bash (no bash-preexec) has no preexec hook, so use a DEBUG trap. It is
# set here, outside any function, and only when duration tracking is enabled.
#
# bash hides the DEBUG trap from sourced files (unless functrace is on), so a
# DEBUG trap set before this file is sourced cannot be seen from here: it is
# replaced, and one set later (a plugin, bash-preexec) replaces this one. What
# was decided is logged, so "gshell doctor" shows why commands are not timed.
if [[ -n "${BASH_VERSION:-}" && $- == *i* ]] && ! type -t __bp_precmd_invoke_cmd &>/dev/null; then
	if [[ -n "${GAUDI_SHELL_COMMAND_DURATION:-}" ]]; then
		trap '_command_duration_debug_trap "$_"' DEBUG
		type _log_debug &>/dev/null &&
			_log_debug "command duration: commands are timed with a DEBUG trap (it replaces one set earlier, and one set later replaces it)"
	else
		# Setting the variable later in the session has no effect in plain bash.
		type _log_debug &>/dev/null &&
			_log_debug "command duration is off: set GAUDI_SHELL_COMMAND_DURATION=true before gaudi-shell is sourced to time commands"
	fi
fi

_command_duration() {
	[[ -n "${GAUDI_SHELL_COMMAND_DURATION:-}" ]] || return
	[[ -n "${COMMAND_DURATION_START_SECONDS:-}" ]] || return

	local current_time
	current_time="$(_command_duration_current_time)"

	local -i command_duration=0 minutes=0 seconds=0
	local microseconds=""
	local -i command_start_seconds=${COMMAND_DURATION_START_SECONDS%.*}
	local -i current_time_seconds=${current_time%.*}

	command_duration=$((current_time_seconds - command_start_seconds))

	if [[ "$COMMAND_DURATION_START_SECONDS" == *.* ]] && [[ "$current_time" == *.* ]] && ((COMMAND_DURATION_PRECISION > 0)); then
		local -i command_start_microseconds=$((10#${COMMAND_DURATION_START_SECONDS##*.}))
		local -i current_time_microseconds=$((10#${current_time##*.}))

		if ((current_time_microseconds >= command_start_microseconds)); then
			microseconds=$((current_time_microseconds - command_start_microseconds))
		else
			((command_duration -= 1))
			microseconds=$((1000000 + current_time_microseconds - command_start_microseconds))
		fi
		printf -v microseconds '%06d' "$microseconds"
		microseconds="${microseconds:0:$COMMAND_DURATION_PRECISION}"
	fi

	if ((command_duration >= COMMAND_DURATION_MIN_SECONDS)); then
		minutes=$((command_duration / 60))
		seconds=$((command_duration % 60))

		if ((minutes > 0)); then
			printf "%dm %ds" "$minutes" "$seconds"
		else
			printf "%ss" "$seconds${microseconds:+.$microseconds}"
		fi
	fi
}
