#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs log utils
}

@test "gaudi-shell helpers: utils: _is_function: should succeed for a defined function" {
	test_function() { echo "test"; }
	run _is_function test_function
	assert_success
}

@test "gaudi-shell helpers: utils: _is_function: should fail for a non-function" {
	run _is_function "not_a_function"
	assert_failure
}

@test "gaudi-shell helpers: utils: _command_exists: should succeed for ls" {
	run _command_exists ls
	assert_success
}

@test "gaudi-shell helpers: utils: _command_exists: should fail for non-existent command" {
	run _command_exists __nonexistent_command_xyz
	assert_failure
}

@test "gaudi-shell helpers: utils: _array-contains: should find element in array" {
	declare -a fruits=(apple orange pear)
	run _array-contains "pear" "${fruits[@]}"
	assert_success
}

@test "gaudi-shell helpers: utils: _array-contains: should fail for missing element" {
	declare -a fruits=(apple orange pear)
	run _array-contains "grape" "${fruits[@]}"
	assert_failure
}

@test "gaudi-shell helpers: utils: _clean-string: should trim all whitespace" {
	run _clean-string " test test test " "any"
	assert_output "testtesttest"
}

@test "gaudi-shell helpers: utils: _clean-string: should trim leading and trailing" {
	run _clean-string " test test test " "all"
	assert_output "test test test"
}

@test "gaudi-shell helpers: utils: _array-dedupe: should remove duplicates" {
	declare -a a=(apple orange pear)
	declare -a b=(apple pear apricot)
	run _array-dedupe "${a[@]}" "${b[@]}"
	assert_output "apple apricot orange pear"
}

@test "gaudi-shell helpers: utils: _read_input: should accept yes" {
	run _read_input "Sure? [yY/nN]" <<<"y"
	assert_success
	assert_output --partial "Sure? [yY/nN]"
}

@test "gaudi-shell helpers: utils: _read_input: should return non-zero for no" {
	run _read_input "Sure? [yY/nN]" <<<"N"
	assert_failure 1
}

@test "gaudi-shell helpers: utils: _read_input: should ask again after an invalid answer" {
	run _read_input "Sure?" < <(printf '%s\n' "maybe" "Y")
	assert_success
}

@test "gaudi-shell helpers: utils: _read_input: should set REPLY to the answer" {
	_read_input "Sure?" <<<"y" >/dev/null
	assert_equal "$REPLY" "y"
}

@test "gaudi-shell helpers: utils: _read_input: should stop instead of looping when nothing can be read" {
	run _read_input "Sure?" </dev/null
	assert_failure 2

	# An invalid answer followed by end of input ends the loop as well
	run _read_input "Sure?" <<<"maybe"
	assert_failure 2

	local status_code=0
	_read_input "Sure?" </dev/null >/dev/null || status_code=$?
	assert_equal "$status_code" 2
	assert_equal "$REPLY" ""
}
