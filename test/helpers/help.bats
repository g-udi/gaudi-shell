#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs gaudi-shell help
}

@test "gaudi-shell-helpers: help: should show usage when no valid argument passed" {
	run _gaudi-shell-help INVALID
	assert_success
	assert_output --partial "Usage: gshell"
}

@test "gaudi-shell-helpers: help: should print the command list when called without an argument" {
	run gshell help
	assert_success
	assert_output --partial "Usage: gshell <command> [args]"
	local verb
	for verb in show enable disable search help profile backup restore update doctor reload restart version; do
		assert_line --regexp "^  ${verb} "
	done
	refute_output --partial "Run 'gshell help'"
}

@test "gaudi-shell-helpers: help: usage lists every command the dispatcher accepts" {
	local verbs verb
	verbs="$(sed -n '/^gshell() {/,/^}/p' "$GAUDI_SHELL/lib/gaudi-shell.bash" | sed -n 's/^	\([a-z]*\)).*/\1/p')"
	[[ -n "$verbs" ]]
	run _gaudi-shell-usage
	for verb in $verbs; do
		assert_line --regexp "^  ${verb} "
	done
}

@test "gaudi-shell-helpers: help: _gaudi-shell-help aliases without any enabled" {
	run _help-aliases
	# No enabled aliases means no output
	refute_output --partial "alias "
}

@test "gaudi-shell-helpers: help: _gaudi-shell-help aliases with enabled alias" {
	ln -s "$GAUDI_SHELL/components/aliases/git.aliases.bash" \
		"$GAUDI_SHELL/components/enabled/150___git.aliases.bash"

	run _help-aliases
	assert_success
	assert_output --partial "git"
}

@test "gaudi-shell-helpers: help: _gaudi-shell-help completions shows describe output" {
	run _help-completions
	assert_success
}

@test "gaudi-shell-helpers: help: _gaudi-shell-help plugins with enabled plugin" {
	ln -s "$GAUDI_SHELL/components/plugins/base.plugins.bash" \
		"$GAUDI_SHELL/components/enabled/250___base.plugins.bash"

	run _help-plugins
	assert_success
	assert_output --partial "base"
}
