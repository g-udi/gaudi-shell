#!/usr/bin/env bats
# shellcheck shell=bats
# shellcheck disable=SC2030,SC2031,SC2034

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	HISTORY_LIB="$GAUDI_SHELL/lib/history.bash"
}

# Runs the snippet in a fresh bash that then sources the history library.
_history_after() {
	# shellcheck disable=SC2016
	run "$BASH" --noprofile --norc -c "$1"$'\n''source "$0"; echo "$HISTSIZE|$HISTFILESIZE|$HISTCONTROL"' "$HISTORY_LIB"
}

@test "gaudi-shell lib: history: small shell defaults are raised" {
	_history_after 'HISTSIZE=500; HISTFILESIZE=500; unset HISTCONTROL'
	assert_success
	assert_output "10000|20000|ignoredups:ignorespace"
}

@test "gaudi-shell lib: history: larger sizes and a HISTCONTROL set by the user are kept" {
	_history_after 'HISTSIZE=50000; HISTFILESIZE=100000; HISTCONTROL=erasedups'
	assert_success
	assert_output "50000|100000|erasedups"
}

@test "gaudi-shell lib: history: unlimited history is left alone" {
	_history_after 'HISTSIZE=-1; HISTFILESIZE=-1'
	assert_success
	assert_output "-1|-1|ignoredups:ignorespace"
}
