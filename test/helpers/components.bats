#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs log gaudi-shell components cache core utils
}

@test "gaudi-shell helpers: components: __check-function-parameters: valid component" {
	run __check-function-parameters plugin
	assert_success
}

@test "gaudi-shell helpers: components: __check-function-parameters: invalid component" {
	run __check-function-parameters invalid
	assert_failure
}

@test "gaudi-shell helpers: components: pluralize" {
	run _gaudi-shell-pluralize-component plugin
	assert_output "plugins"

	run _gaudi-shell-pluralize-component alias
	assert_output "aliases"

	run _gaudi-shell-pluralize-component completion
	assert_output "completions"
}

@test "gaudi-shell helpers: components: singularize" {
	run _gaudi-shell-singularize-component plugins
	assert_output "plugin"

	run _gaudi-shell-singularize-component aliases
	assert_output "alias"

	run _gaudi-shell-singularize-component completions
	assert_output "completion"
}

@test "gaudi-shell helpers: components: list contains only real alias components" {
	local expected actual

	# Everything in the shared repository except the other framework's own
	# file, plus this framework's own file from components/host
	expected="$(find "${GAUDI_SHELL}/components/aliases/lib" "${GAUDI_SHELL}/components/host" -maxdepth 1 -type f -name '*.aliases.bash' ! -name 'gaudi-bash.*' -exec basename {} .aliases.bash \; | sort | tr '\n' ' ')"

	run _gaudi-shell-component-list aliases
	assert_success

	actual="$(printf '%s' "$output" | tr ' ' '\n' | sed '/^$/d' | sort | tr '\n' ' ')"
	assert_equal "$expected" "$actual"
}

# --- where component files live ---

@test "gaudi-shell helpers: components: component-file finds a shared component under its submodule's lib folder" {
	run _gaudi-shell-component-file alias git
	assert_success
	assert_output "$GAUDI_SHELL/components/aliases/lib/git.aliases.bash"

	# Singular and plural type names are the same thing
	run _gaudi-shell-component-file plugins base
	assert_output "$GAUDI_SHELL/components/plugins/lib/base.plugins.bash"
}

@test "gaudi-shell helpers: components: component-file finds the framework's own files in components/host" {
	run _gaudi-shell-component-file completion gaudi-shell
	assert_success
	assert_output "$GAUDI_SHELL/components/host/gaudi-shell.completions.bash"

	run _gaudi-shell-component-file alias gaudi-shell
	assert_output "$GAUDI_SHELL/components/host/gaudi-shell.aliases.bash"
}

@test "gaudi-shell helpers: components: component-file looks in components/host first" {
	echo "alias host_git='true'" >"$GAUDI_SHELL/components/host/git.aliases.bash"

	run _gaudi-shell-component-file alias git
	assert_success
	assert_output "$GAUDI_SHELL/components/host/git.aliases.bash"

	# ... and the lister gives that component once, from components/host
	run _gaudi-shell-component-files aliases
	assert_line "$GAUDI_SHELL/components/host/git.aliases.bash"
	refute_line "$GAUDI_SHELL/components/aliases/lib/git.aliases.bash"
}

@test "gaudi-shell helpers: components: component-file fails for an unknown component or type" {
	run _gaudi-shell-component-file alias no-such-component
	assert_failure
	assert_output ""

	run _gaudi-shell-component-file theme git
	assert_failure

	run _gaudi-shell-component-file alias
	assert_failure
}

@test "gaudi-shell helpers: components: component-files lists host and shared files sorted by name" {
	run _gaudi-shell-component-files aliases
	assert_success
	assert_line "$GAUDI_SHELL/components/host/gaudi-shell.aliases.bash"
	assert_line "$GAUDI_SHELL/components/aliases/lib/git.aliases.bash"

	local names sorted
	names="$(printf '%s\n' "$output" | sed 's|.*/||')"
	sorted="$(printf '%s\n' "$names" | sort)"
	assert_equal "$names" "$sorted"
	# Only files of that type
	refute_output --partial ".completions.bash"
	refute_output --partial ".zsh"
}

@test "gaudi-shell helpers: components: link-target is relative to components/enabled" {
	run _gaudi-shell-component-link-target "$GAUDI_SHELL/components/aliases/lib/git.aliases.bash"
	assert_output "../aliases/lib/git.aliases.bash"

	run _gaudi-shell-component-link-target "$GAUDI_SHELL/components/host/gaudi-shell.completions.bash"
	assert_output "../host/gaudi-shell.completions.bash"
}

# --- the other framework's own files ---

@test "gaudi-shell helpers: components: another framework's own files are in the shared repositories but not offered" {
	# They are there ...
	assert_file_exist "$GAUDI_SHELL/components/aliases/lib/gaudi-bash.aliases.bash"
	assert_file_exist "$GAUDI_SHELL/components/completions/lib/gaudi-bash.completions.bash"

	# ... and hidden by the one rule
	run _gaudi-shell-component-is-foreign gaudi-bash
	assert_success
	run _gaudi-shell-component-is-foreign gaudi-shell
	assert_failure
	run _gaudi-shell-component-is-foreign git
	assert_failure

	run _gaudi-shell-component-file alias gaudi-bash
	assert_failure
	run _gaudi-shell-component-file completion gaudi-bash
	assert_failure

	run _gaudi-shell-component-files aliases
	refute_output --partial "gaudi-bash"
	run _gaudi-shell-component-files completions
	refute_output --partial "gaudi-bash"
}

@test "gaudi-shell helpers: components: the host's own name is never foreign, whatever the list says" {
	# shellcheck disable=SC2034
	GAUDI_SHELL_FOREIGN_HOSTS="gaudi-bash gaudi-shell"
	run _gaudi-shell-component-is-foreign gaudi-shell
	assert_failure
	run _gaudi-shell-component-file alias gaudi-shell
	assert_success
}

@test "gaudi-shell helpers: components: another framework's own files are hidden from show, search, enable and profiles" {
	load_gaudi_libs enabler disabler profile search

	run _gaudi-shell-describe aliases
	assert_line --regexp "^gaudi-shell +"
	refute_line --regexp "^gaudi-bash +"
	run _gaudi-shell-describe completions
	assert_line --regexp "^gaudi-shell +"
	refute_line --regexp "^gaudi-bash +"

	run _gaudi-shell-search --no-color gaudi
	assert_output --partial "gaudi-shell"
	refute_output --partial "gaudi-bash"
	run _gaudi-shell-search --no-color @gaudi-bash
	refute_output --partial "gaudi-bash"

	run _gaudi-shell-enable alias gaudi-bash
	assert_failure
	assert_output --partial "does not appear to be an available"
	assert_file_not_exist "$GAUDI_SHELL/components/enabled/150___gaudi-bash.aliases.bash"

	run _gaudi-shell-enable aliases all
	assert_success
	assert_link_exist "$GAUDI_SHELL/components/enabled/150___gaudi-shell.aliases.bash"
	assert_link_exist "$GAUDI_SHELL/components/enabled/150___git.aliases.bash"
	run find "$GAUDI_SHELL/components/enabled" -name '*gaudi-bash*'
	assert_output ""

	mkdir -p "$GAUDI_SHELL/profiles"
	echo "alias gaudi-bash" >"$GAUDI_SHELL/profiles/foreign.gaudi-shell"
	run _gaudi-shell-profile-check "$GAUDI_SHELL/profiles/foreign.gaudi-shell"
	assert_failure
	assert_output --partial "Unknown alias"
}
