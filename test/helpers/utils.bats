#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs log utils
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

@test "gaudi-shell helpers: utils: _binary_exists: should succeed for a program on PATH" {
	run _binary_exists ls
	assert_success
}

@test "gaudi-shell helpers: utils: _binary_exists: should fail for a missing program" {
	run _binary_exists __nonexistent_command_xyz
	assert_failure
}

@test "gaudi-shell helpers: utils: _binary_exists: a function or an alias is not a binary" {
	__gaudi_test_only_function() { :; }
	alias __gaudi_test_only_alias='ls'

	run _binary_exists __gaudi_test_only_function
	assert_failure
	run _binary_exists __gaudi_test_only_alias
	assert_failure
	# ...while _command_exists accepts the function
	run _command_exists __gaudi_test_only_function
	assert_success
}

@test "gaudi-shell helpers: utils: host contract: the names components rely on are defined" {
	assert_equal "$GAUDI_HOST_NAME" "gaudi-shell"
	assert_equal "$GAUDI_HOST_COMMAND" "gshell"
	assert_equal "$GAUDI_HOST_HOME" "$GAUDI_SHELL"
	run type -t _gaudi_host_setting
	assert_output "function"
}

@test "gaudi-shell helpers: utils: host contract: the sed in-place arguments follow the framework's" {
	load_gaudi_libs generic utils
	assert_equal "${#GAUDI_HOST_SED_I_PARAMETERS[@]}" "${#GAUDI_SHELL_SED_I_PARAMETERS[@]}"
	assert_equal "${GAUDI_HOST_SED_I_PARAMETERS[0]}" "-i"
}

@test "gaudi-shell helpers: utils: _gaudi_host_setting: reads GAUDI_<name>, then GAUDI_SHELL_<name>" {
	unset GAUDI_HTTP_PROXY GAUDI_SHELL_HTTP_PROXY
	run _gaudi_host_setting HTTP_PROXY
	assert_success
	assert_output ""

	GAUDI_SHELL_HTTP_PROXY="http://shell:1"
	run _gaudi_host_setting HTTP_PROXY
	assert_output "http://shell:1"

	GAUDI_HTTP_PROXY="http://neutral:2"
	run _gaudi_host_setting HTTP_PROXY
	assert_output "http://neutral:2"
}

@test "gaudi-shell helpers: utils: _gaudi_host_setting: refuses anything that is not a setting name" {
	run _gaudi_host_setting 'X:-$(echo injected)'
	assert_failure
	assert_output ""
	run _gaudi_host_setting ""
	assert_failure
}

@test "gaudi-shell helpers: utils: _homebrew-check: sets the prefix under both names, calling brew once" {
	mkdir -p "$BATS_TEST_TMPDIR/bin"
	cat >"$BATS_TEST_TMPDIR/bin/brew" <<BREW
#!/bin/sh
echo called >>"$BATS_TEST_TMPDIR/brew.calls"
echo /fake/homebrew
BREW
	chmod +x "$BATS_TEST_TMPDIR/bin/brew"
	local PATH="$BATS_TEST_TMPDIR/bin:/usr/bin:/bin"
	unset GAUDI_HOST_HOMEBREW_PREFIX GAUDI_SHELL_HOMEBREW_PREFIX

	_homebrew-check
	_homebrew-check
	assert_equal "$GAUDI_HOST_HOMEBREW_PREFIX" "/fake/homebrew"
	assert_equal "$GAUDI_SHELL_HOMEBREW_PREFIX" "/fake/homebrew"
	run cat "$BATS_TEST_TMPDIR/brew.calls"
	assert_output "called"
}

@test "gaudi-shell helpers: utils: _homebrew-check: fails and clears the prefix without brew" {
	local PATH="/usr/bin:/bin"
	GAUDI_HOST_HOMEBREW_PREFIX="/stale"
	GAUDI_SHELL_HOMEBREW_PREFIX="/stale"

	run _homebrew-check
	assert_failure
	_homebrew-check || true
	assert_equal "$GAUDI_HOST_HOMEBREW_PREFIX" ""
	assert_equal "$GAUDI_SHELL_HOMEBREW_PREFIX" ""
}

@test "gaudi-shell helpers: utils: host contract: shared components do not name a framework" {
	# aliases, completions and plugins are shared with gaudi-bash; only the
	# framework's own files (gaudi-shell.*) may name it
	run grep -rlE 'GAUDI_(SHELL|BASH)|gaudi[-_](shell|bash)|\bg(shell|bash)\b' \
		--include='*.bash' --exclude='gaudi-shell.*' \
		"$GAUDI_SHELL/components/aliases" "$GAUDI_SHELL/components/completions" "$GAUDI_SHELL/components/plugins"
	assert_output ""
}
