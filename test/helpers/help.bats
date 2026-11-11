#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs composure gaudi-shell help search
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

@test "gaudi-shell-helpers: help: usage, dispatcher and handlers all come from the one command table" {
	local verbs verb
	verbs="$(_gaudi-shell-verb-names)"
	[[ -n "$verbs" ]]
	run _gaudi-shell-usage
	for verb in $verbs; do
		# Listed in the usage text
		assert_line --regexp "^  ${verb}( |$)"
		# Has a handler the dispatcher can call
		declare -F "_gaudi-shell-${verb}" >/dev/null
	done
	# 14 commands, and nothing else is dispatched
	assert_equal "$(wc -w <<<"$verbs" | tr -d ' ')" "14"
}

@test "gaudi-shell-helpers: help: the command table gives the words each command completes" {
	run _gaudi-shell-verb-field show 4
	assert_output "aliases plugins completions"
	run _gaudi-shell-verb-field show 5
	assert_output "enabled"
	run _gaudi-shell-verb-field doctor 4
	assert_output "errors warnings all"
	run _gaudi-shell-verb-field reload 4
	assert_output ""
	run _gaudi-shell-verb-field nonsense 1
	assert_failure
}

@test "gaudi-shell-helpers: help: _gaudi-shell-help aliases without any enabled" {
	run _help-aliases
	# No enabled aliases means no output
	refute_output --partial "alias "
}

@test "gaudi-shell-helpers: help: _gaudi-shell-help aliases with enabled alias" {
	ln -s "$GAUDI_SHELL/components/aliases/lib/git.aliases.bash" \
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
	ln -s "$GAUDI_SHELL/components/plugins/lib/base.plugins.bash" \
		"$GAUDI_SHELL/components/enabled/250___base.plugins.bash"

	run _help-plugins
	assert_success
	assert_output --partial "base"
}
