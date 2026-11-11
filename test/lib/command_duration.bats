#!/usr/bin/env bats
# shellcheck shell=bats
# shellcheck disable=SC2030,SC2031,SC2034

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs command_duration
}

@test "gaudi-shell lib: command_duration: should return a numeric value" {
	run _command_duration_current_time
	assert_success
	assert_output --regexp '^[0-9]+\.?[0-9]*$'
}

@test "gaudi-shell lib: command_duration: should return empty when disabled" {
	unset GAUDI_SHELL_COMMAND_DURATION
	COMMAND_DURATION_START_SECONDS="$(_command_duration_current_time)"
	run _command_duration
	assert_output ""
}

@test "gaudi-shell lib: command_duration: should return empty for short commands" {
	GAUDI_SHELL_COMMAND_DURATION=true
	COMMAND_DURATION_MIN_SECONDS=5
	COMMAND_DURATION_START_SECONDS="$(_command_duration_current_time)"
	run _command_duration
	assert_success
	assert_output ""
}

@test "gaudi-shell lib: command_duration: should format minutes and seconds" {
	GAUDI_SHELL_COMMAND_DURATION=true
	COMMAND_DURATION_MIN_SECONDS=1
	COMMAND_DURATION_PRECISION=0
	local current_time
	current_time="$(_command_duration_current_time)"
	COMMAND_DURATION_START_SECONDS="$((${current_time%.*} - 125))"
	run _command_duration
	assert_success
	assert_output --partial "2m 5s"
}

@test "gaudi-shell lib: command_duration: should format seconds for short durations" {
	GAUDI_SHELL_COMMAND_DURATION=true
	COMMAND_DURATION_MIN_SECONDS=1
	COMMAND_DURATION_PRECISION=0
	local current_time
	current_time="$(_command_duration_current_time)"
	COMMAND_DURATION_START_SECONDS="$((${current_time%.*} - 5))"
	run _command_duration
	assert_success
	assert_output --partial "5s"
}

@test "gaudi-shell lib: command_duration: pre_exec starts the timer only when enabled" {
	COMMAND_DURATION_START_SECONDS=""
	unset GAUDI_SHELL_COMMAND_DURATION
	_command_duration_pre_exec
	[[ -z "$COMMAND_DURATION_START_SECONDS" ]]

	GAUDI_SHELL_COMMAND_DURATION=true
	_command_duration_pre_exec
	[[ "$COMMAND_DURATION_START_SECONDS" =~ ^[0-9]+\.?[0-9]*$ ]]
}

@test "gaudi-shell lib: command_duration: pre_cmd resets the timer so no duration is shown" {
	GAUDI_SHELL_COMMAND_DURATION=true
	COMMAND_DURATION_MIN_SECONDS=0
	_command_duration_pre_exec
	_command_duration_pre_cmd
	[[ -z "$COMMAND_DURATION_START_SECONDS" ]]
	run _command_duration
	assert_output ""
}

@test "gaudi-shell lib: command_duration: registers itself as a finalize hook" {
	run printf '%s\n' "${GAUDI_SHELL_FINALIZE_HOOKS[@]}"
	assert_line "_command_duration_register_hooks"
}

@test "gaudi-shell lib: command_duration: debug trap times only the first command after a prompt" {
	GAUDI_SHELL_COMMAND_DURATION=true
	PROMPT_COMMAND="some_prompt_function"
	COMMAND_DURATION_START_SECONDS=""

	# Not at a prompt yet (shell start-up): ignored
	_command_duration_debug_trap
	[[ -z "$COMMAND_DURATION_START_SECONDS" ]]

	_command_duration_pre_cmd
	_command_duration_debug_trap
	[[ -n "$COMMAND_DURATION_START_SECONDS" ]]

	# Later commands of the same line do not restart the timer
	COMMAND_DURATION_START_SECONDS="marker"
	_command_duration_debug_trap
	[[ "$COMMAND_DURATION_START_SECONDS" == "marker" ]]
}

@test "gaudi-shell lib: command_duration: interactive bash times a command and resets at the next prompt" {
	local rc="${BATS_TEST_TMPDIR}/rc" report="${BATS_TEST_TMPDIR}/report"
	cat >"$rc" <<EOF
export GAUDI_SHELL="$GAUDI_SHELL"
export GAUDI_SHELL_COMMAND_DURATION=true
unset GAUDI_SHELL_THEME
source "\$GAUDI_SHELL/adapters/bash/init.bash"
PS1=""
_report() { echo "duration=[\$(COMMAND_DURATION_MIN_SECONDS=0 COMMAND_DURATION_PRECISION=0 _command_duration)]" >>"$report"; }
PROMPT_COMMAND=\$'_report\n'"\$PROMPT_COMMAND"
EOF
	# One prompt at start-up, one after "sleep 1", one after the empty line
	bash --noprofile --rcfile "$rc" -i <<<$'sleep 1\n' >/dev/null 2>&1 || true

	run cat "$report"
	assert_line --index 1 --regexp '^duration=\[[1-9][0-9]*s\]$'
	assert_line --index 2 "duration=[]"
}
