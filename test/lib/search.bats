#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs composure gaudi-shell search
}

@test "gaudi-shell search: exact matches ignore show usage footer tokens" {
	run _gaudi-shell-search @to --no-color

	assert_failure
	assert_output ""
}

@test "gaudi-shell search: help names the gshell command and only the flags that exist" {
	run _gaudi-shell-search --help

	assert_success
	assert_output --partial "gshell search [-|@]term1"
	refute_output --partial "gaudi-shell search"
	refute_output --partial "| -e"
	refute_output --partial "| -d"
	assert_output --partial "--no-color   | -x"
	assert_output --partial "--completion | -c"
}

@test "gaudi-shell search: every short flag in the help is handled by the parser" {
	local flags flag
	flags="$(_gaudi-shell-search --help | sed -n 's/^ *--[a-z-]* *| \(-[a-z]\) .*/\1/p' | sort -u)"
	[[ -n "$flags" ]]
	for flag in $flags; do
		run grep -c -- "'${flag}' | '--" "$GAUDI_SHELL/lib/search.bash"
		assert_output "1"
	done
}
