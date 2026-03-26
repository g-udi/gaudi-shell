#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs gaudi-shell help
}

@test "gaudi-shell-helpers: help: should show usage when no valid argument passed" {
	run _gaudi-shell-help INVALID
	assert_success
	assert_output --partial "Usage: gaudi"
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
