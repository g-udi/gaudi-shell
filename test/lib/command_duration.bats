#!/usr/bin/env bats
# shellcheck shell=bats
# shellcheck disable=SC2034

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
