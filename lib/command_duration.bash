#!/usr/bin/env bash
# shellcheck shell=bash
#
# Command execution duration tracking.
# Uses EPOCHREALTIME for sub-second precision, falls back to $SECONDS.

_command_duration_current_time() {
	local current_time
	if [[ -n "${EPOCHREALTIME:-}" ]]; then
		current_time="${EPOCHREALTIME//[!0-9]/.}"
	else
		current_time="$SECONDS"
	fi
	echo "$current_time"
}

: "${COMMAND_DURATION_START_SECONDS:=$(_command_duration_current_time)}"
: "${COMMAND_DURATION_MIN_SECONDS:=1}"
: "${COMMAND_DURATION_PRECISION:=1}"

_command_duration_pre_exec() {
	COMMAND_DURATION_START_SECONDS="$(_command_duration_current_time)"
}

_command_duration_pre_cmd() {
	COMMAND_DURATION_START_SECONDS=""
}

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
