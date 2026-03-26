#!/usr/bin/env bats
# shellcheck shell=bats
# shellcheck disable=SC2034

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs log gaudi-shell doctor
}

@test "gaudi-shell helpers: doctor: _gaudi-shell-doctor should show all logs by default" {
	run _gaudi-shell-doctor
	assert_success
}

@test "gaudi-shell helpers: doctor: _gaudi-shell-doctor should show only warning logs" {
	run _gaudi-shell-doctor warnings
	assert_success
}

@test "gaudi-shell helpers: doctor: _gaudi-shell-doctor should only show error logs" {
	GAUDI_SHELL_LOG_LEVEL=0
	run _gaudi-shell-doctor errors
	assert_success
}
