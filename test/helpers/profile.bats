#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs log colors gaudi-shell
}

_enabled() {
	(cd "$GAUDI_SHELL/components/enabled" && ls)
}

@test "gaudi-shell profile: save writes one '<type> <name>' line per enabled component" {
	gshell enable alias general >/dev/null
	gshell enable plugin base >/dev/null

	run gshell profile save work
	assert_success
	assert_output --partial "2 component(s)"

	run cat "$GAUDI_SHELL/profiles/work.gaudi-shell"
	assert_line --index 0 "alias general"
	assert_line --index 1 "plugin base"
}

@test "gaudi-shell profile: load switches to the components of the profile" {
	gshell enable alias general >/dev/null
	gshell profile save one >/dev/null
	gshell disable alias general >/dev/null
	gshell enable plugin base >/dev/null

	run gshell profile load one
	assert_success
	assert_output --partial "loaded"

	run _enabled
	assert_output "150___general.aliases.bash"
}

@test "gaudi-shell profile: load with a component that does not exist changes nothing" {
	gshell enable alias general >/dev/null
	gshell enable plugin base >/dev/null
	printf '%s\n' "alias git" "plugin no-such-plugin" >"$GAUDI_SHELL/profiles/broken.gaudi-shell"

	run gshell profile load broken
	assert_failure
	assert_output --partial "Unknown plugin"
	assert_output --partial "no-such-plugin"
	assert_output --partial "nothing was changed"
	refute_output --partial "disabled"

	# Exactly what was enabled before
	run _enabled
	assert_line --index 0 "150___general.aliases.bash"
	assert_line --index 1 "250___base.plugins.bash"
	assert_equal "${#lines[@]}" "2"
}

@test "gaudi-shell profile: load with a malformed line changes nothing" {
	gshell enable alias general >/dev/null
	printf '%s\n' "alias git" "rm -rf /" >"$GAUDI_SHELL/profiles/broken.gaudi-shell"

	run gshell profile load broken
	assert_failure
	assert_output --partial "Invalid entry"

	run _enabled
	assert_output "150___general.aliases.bash"
}

@test "gaudi-shell profile: load of a missing profile and unknown subcommands fail" {
	run gshell profile load nope
	assert_failure
	assert_output --partial "not found"

	run gshell profile frobnicate
	assert_failure

	run gshell profile
	assert_failure
	assert_output --partial "Usage: gshell profile"
}

@test "gaudi-shell profile: the name used by 'gshell backup' cannot be saved over" {
	run gshell profile save backup
	assert_failure
	assert_output --partial "gshell backup"
	assert_file_not_exist "$GAUDI_SHELL/profiles/backup.gaudi-shell"
}

@test "gaudi-shell profile: list and rm" {
	rm -f "$GAUDI_SHELL"/profiles/*.gaudi-shell
	run gshell profile list
	assert_success
	assert_output --partial "No profiles found"

	gshell enable alias general >/dev/null
	gshell profile save one >/dev/null

	run gshell profile list
	assert_line --partial "Available profiles:"
	assert_line --partial "one"
	assert_line --partial "(1 component(s))"

	run gshell profile rm one
	assert_success
	assert_file_not_exist "$GAUDI_SHELL/profiles/one.gaudi-shell"

	run gshell profile rm one
	assert_failure
}

@test "gaudi-shell profile: an existing profile is only overwritten after a yes" {
	gshell enable alias general >/dev/null
	gshell profile save one >/dev/null
	gshell enable plugin base >/dev/null

	run gshell profile save one <<<"n"
	assert_output --partial "cancelled"
	run cat "$GAUDI_SHELL/profiles/one.gaudi-shell"
	assert_output "alias general"

	run gshell profile save one <<<"y"
	assert_output --partial "2 component(s)"
}
