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

@test "gaudi-shell lib: command_duration: nothing is shown before the first command" {
	GAUDI_SHELL_COMMAND_DURATION=true
	COMMAND_DURATION_MIN_SECONDS=0
	# As set when the library is loaded
	[[ -z "$COMMAND_DURATION_START_SECONDS" ]]
	run _command_duration
	assert_output ""
}

@test "gaudi-shell lib: command_duration: only whole PROMPT_COMMAND entries are ignored by the trap" {
	GAUDI_SHELL_COMMAND_DURATION=true
	PROMPT_COMMAND=$'gaudi::prompt\nhistory -a;  update_terminal_cwd ; _command_duration_pre_cmd'

	run _command_duration_is_prompt_command "gaudi::prompt"
	assert_success
	run _command_duration_is_prompt_command "history -a"
	assert_success
	run _command_duration_is_prompt_command "update_terminal_cwd"
	assert_success

	# Typed by the user: parts of the entries above, but not whole entries
	run _command_duration_is_prompt_command ":"
	assert_failure
	run _command_duration_is_prompt_command "history"
	assert_failure
	run _command_duration_is_prompt_command "update"
	assert_failure

	_command_duration_pre_cmd
	# A short command typed at the prompt starts the timer
	COMMAND_DURATION_START_SECONDS=""
	_COMMAND_DURATION_AT_PROMPT=1
	_command_duration_is_prompt_command "history" || _command_duration_pre_exec
	[[ -n "$COMMAND_DURATION_START_SECONDS" ]]
}

@test "gaudi-shell lib: command_duration: PROMPT_COMMAND as an array is understood" {
	if ((BASH_VERSINFO[0] < 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] < 1))); then
		skip "PROMPT_COMMAND can be an array from bash 5.1"
	fi
	PROMPT_COMMAND=(first "second; third")
	run _command_duration_is_prompt_command "third"
	assert_success
	run _command_duration_is_prompt_command "fourth"
	assert_failure
}

@test "gaudi-shell lib: command_duration: the log says whether commands are timed" {
	local rc="${BATS_TEST_TMPDIR}/rc" report="${BATS_TEST_TMPDIR}/report"
	cat >"$rc" <<EOF_RC
export GAUDI_SHELL="$GAUDI_SHELL"
export GAUDI_SHELL_LOG_LEVEL=3
unset GAUDI_SHELL_THEME
source "\$GAUDI_SHELL/adapters/bash/init.bash" >"$report.off" 2>&1
trap -p DEBUG >"$report.off.trap"
export GAUDI_SHELL_COMMAND_DURATION=true
source "\$GAUDI_SHELL/adapters/bash/init.bash" >"$report.on" 2>&1
trap -p DEBUG >"$report.on.trap"
EOF_RC
	bash --noprofile --rcfile "$rc" -i <<<$'true\n' >/dev/null 2>&1 || true

	# Not enabled when gaudi-shell was sourced: no trap, and the log says why
	run cat "$report.off"
	assert_output --partial "command duration is off"
	run cat "$report.off.trap"
	assert_output ""

	run cat "$report.on"
	assert_output --partial "commands are timed with a DEBUG trap"
	run cat "$report.on.trap"
	assert_output --partial "_command_duration_debug_trap"
}
