#!/usr/bin/env bats
# shellcheck shell=bats
# shellcheck disable=SC2034,SC2207

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs gaudi-shell
	source "$GAUDI_SHELL/components/completions/gaudi-shell.completions.bash"
}

# Helper: simulate bash tab completion
_complete_at() {
	COMP_WORDS=("$@")
	COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))
	COMPREPLY=()
	_gaudi-shell-comp
	echo "${COMPREPLY[*]}"
}

# --- Top-level ---

@test "bash completion: top level lists all commands" {
	run _complete_at gaudi ""
	assert_success
	assert_output --partial "show"
	assert_output --partial "enable"
	assert_output --partial "disable"
	assert_output --partial "profile"
	assert_output --partial "version"
}

@test "bash completion: partial match filters results" {
	run _complete_at gaudi "en"
	assert_success
	assert_output --partial "enable"
	refute_output --partial "disable"
}

# --- show ---

@test "bash completion: show lists component types" {
	run _complete_at gaudi show ""
	assert_success
	assert_output --partial "aliases"
	assert_output --partial "plugins"
	assert_output --partial "completions"
}

# --- enable ---

@test "bash completion: enable lists component types" {
	run _complete_at gaudi enable ""
	assert_success
	assert_output --partial "alias"
	assert_output --partial "plugin"
	assert_output --partial "completion"
}

@test "bash completion: enable alias lists available aliases" {
	run _complete_at gaudi enable alias ""
	assert_success
	assert_output --partial "git"
	assert_output --partial "all"
}

@test "bash completion: enable plugin lists available plugins" {
	run _complete_at gaudi enable plugin ""
	assert_success
	assert_output --partial "sudo"
	assert_output --partial "extract"
	assert_output --partial "all"
}

@test "bash completion: enable alias excludes already enabled" {
	ln -s "$GAUDI_SHELL/components/aliases/git.aliases.bash" \
		"$GAUDI_SHELL/components/enabled/150___git.aliases.bash"

	run _complete_at gaudi enable alias "g"
	assert_success
	# git should not appear, but general, gaudi-shell, gls, gitsvn should
	refute_output --partial "git "
}

# --- disable ---

@test "bash completion: disable plugin lists only enabled plugins" {
	ln -s "$GAUDI_SHELL/components/plugins/base.plugins.bash" \
		"$GAUDI_SHELL/components/enabled/250___base.plugins.bash"

	run _complete_at gaudi disable plugin ""
	assert_success
	assert_output --partial "base"
	assert_output --partial "all"
}

@test "bash completion: disable alias with nothing enabled shows only all" {
	run _complete_at gaudi disable alias ""
	assert_success
	assert_output "all"
}

# --- profile ---

@test "bash completion: profile lists subcommands" {
	run _complete_at gaudi profile ""
	assert_success
	assert_output --partial "save"
	assert_output --partial "load"
	assert_output --partial "list"
	assert_output --partial "rm"
}

# --- doctor ---

@test "bash completion: doctor lists log levels" {
	run _complete_at gaudi doctor ""
	assert_success
	assert_output --partial "errors"
	assert_output --partial "warnings"
	assert_output --partial "all"
}

# --- update ---

@test "bash completion: update lists modes" {
	run _complete_at gaudi update ""
	assert_success
	assert_output --partial "stable"
	assert_output --partial "dev"
	assert_output --partial "all"
}

# --- no-arg commands ---

@test "bash completion: reload has no further completions" {
	run _complete_at gaudi reload ""
	assert_success
	assert_output ""
}

@test "bash completion: version has no further completions" {
	run _complete_at gaudi version ""
	assert_success
	assert_output ""
}
