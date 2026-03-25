#!/usr/bin/env bats
# shellcheck shell=bats
# shellcheck disable=SC2034

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs log utils gaudi-shell components
}

@test "gaudi-shell log: _log_general should not log if no message passed" {
	run _log_general
	assert_success
	assert_output ""
}

@test "gaudi-shell log: _log_general should print with default prefix" {
	GAUDI_SHELL_LOG_PREFIX="TEST"
	run _log_general "test message"
	assert_output --partial "GENERAL"
	assert_output --partial "[TEST]"
	assert_output --partial "test message"
}

@test "gaudi-shell log: _log_debug should print when log level is ALL" {
	GAUDI_SHELL_LOG_LEVEL=$GAUDI_SHELL_LOG_LEVEL_ALL
	run _log_debug "debug msg"
	assert_output --partial "DEBUG"
}

@test "gaudi-shell log: _log_debug should not print when log level is ERROR" {
	GAUDI_SHELL_LOG_LEVEL=$GAUDI_SHELL_LOG_LEVEL_ERROR
	run _log_debug "debug msg"
	assert_output ""
}

@test "gaudi-shell log: _log_warning should print when log level is WARNING" {
	GAUDI_SHELL_LOG_LEVEL=$GAUDI_SHELL_LOG_LEVEL_WARNING
	run _log_warning "warn msg"
	assert_output --partial "WARNING"
}

@test "gaudi-shell log: _log_error should print when log level is ERROR" {
	GAUDI_SHELL_LOG_LEVEL=$GAUDI_SHELL_LOG_LEVEL_ERROR
	run _log_error "error msg"
	assert_output --partial "ERROR"
}

@test "gaudi-shell log: component name extraction from path" {
	run _gaudi-shell-get-component-name-from-path "/path/to/250___git.plugins.bash"
	assert_output "git"
}

@test "gaudi-shell log: component type extraction from path" {
	run _gaudi-shell-get-component-type-from-path "/path/to/250___git.plugins.bash"
	assert_output "plugin"
}
