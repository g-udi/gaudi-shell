#!/usr/bin/env bats
# shellcheck shell=bats
# shellcheck disable=SC2034

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs log gaudi-shell doctor
}

# An enabled link whose target is missing: reported from the warning level up.
_enable_a_dangling_link() {
	ln -s "../aliases/lib/no-such.aliases.bash" "$GAUDI_SHELL/components/enabled/150___no-such.aliases.bash"
}

@test "gaudi-shell helpers: doctor: _gaudi-shell-doctor should show all logs by default" {
	_enable_a_dangling_link

	run _gaudi-shell-doctor
	assert_success
	assert_output --partial "[ DEBUG ]"
	assert_output --partial "Loading library: "
	assert_output --partial "points to a missing file"
}

@test "gaudi-shell helpers: doctor: _gaudi-shell-doctor should show only warning logs" {
	_enable_a_dangling_link

	run _gaudi-shell-doctor warnings
	assert_success
	assert_output --partial "points to a missing file"
	refute_output --partial "[ DEBUG ]"
}

@test "gaudi-shell helpers: doctor: _gaudi-shell-doctor should only show error logs" {
	_enable_a_dangling_link

	run _gaudi-shell-doctor errors
	assert_success
	refute_output --partial "points to a missing file"
	refute_output --partial "[ DEBUG ]"
}

@test "gaudi-shell helpers: doctor: _gaudi-shell-doctor should put the log level back" {
	GAUDI_SHELL_LOG_LEVEL=1
	_gaudi-shell-doctor all >/dev/null 2>&1
	assert_equal "$GAUDI_SHELL_LOG_LEVEL" "1"
}
