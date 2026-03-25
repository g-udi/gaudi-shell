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
