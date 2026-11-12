#!/usr/bin/env bats
# shellcheck shell=bats
# shellcheck disable=SC2034

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs gaudi-shell
}

assert_sane_defaults() {
	assert_file_exist "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/325___system.completions.bash"
}

@test "gaudi-shell core: _gaudi-shell-backup should successfully backup enabled components" {

	cd "$GAUDI_SHELL"
	./setup.sh --silent --shell bash

	assert_sane_defaults

	assert_file_not_exist "$GAUDI_SHELL/profiles/backup.gaudi-shell"

	run _gaudi-shell-backup
	assert_success

	# The backup is a profile under a reserved name, in the profile format
	assert_file_exist "$GAUDI_SHELL/profiles/backup.gaudi-shell"

	run cat "$GAUDI_SHELL/profiles/backup.gaudi-shell"
	assert_success
	assert_line "alias general"
	assert_line "plugin base"
	assert_line "completion system"

	run gshell profile list
	assert_line --partial "backup"
}

@test "gaudi-shell core: _gaudi-shell-backup should overwrite old backed up components" {

	cd "$GAUDI_SHELL"
	./setup.sh --silent --shell bash

	assert_sane_defaults

	# A backup file written by an older version
	mkdir -p "$GAUDI_SHELL/tmp"
	printf '%s\n' "gshell enable plugin git" >"$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup"

	run _gaudi-shell-backup

	assert_file_exist "$GAUDI_SHELL/profiles/backup.gaudi-shell"
	# The new backup replaces the old file, which would otherwise be stale
	assert_file_not_exist "$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup"

	run gshell disable completion system
	assert_success
	run _gaudi-shell-backup

	run cat "$GAUDI_SHELL/profiles/backup.gaudi-shell"
	assert_line "alias general"
	refute_line "completion system"
}

@test "gaudi-shell core: _gaudi-shell-restore should successfully restore backed up components" {

	cd "$GAUDI_SHELL"
	./setup.sh --silent --shell bash

	assert_sane_defaults

	run _gaudi-shell-backup

	assert_line --index 0 "Backing up alias: general"
	assert_file_exist "$GAUDI_SHELL/profiles/backup.gaudi-shell"

	run gshell disable plugins all
	run gshell disable completion all
	run gshell disable aliases all

	assert_file_not_exist "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	assert_file_not_exist "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
	assert_file_not_exist "$GAUDI_SHELL/components/enabled/325___system.completions.bash"

	run _gaudi-shell-restore

	assert_sane_defaults

}

@test "gaudi-shell core: _gaudi-shell-show should include usage hints for valid component types" {
	run _gaudi-shell-show aliases

	assert_success
	assert_output --partial "gaudi-shell allows you to easily enable/disable components:"
	assert_output --partial "to enable alias, do:"
	assert_output --partial "to disable alias, do:"
}

@test "gaudi-shell core: _gaudi-shell-show should fail without usage hints for invalid component types" {
	run _gaudi-shell-show invalid

	assert_failure
	refute_output --partial "gaudi-shell allows you to easily enable/disable components:"
}

@test "gaudi-shell core: _gaudi-shell-show should fail without usage hints for invalid modes" {
	run _gaudi-shell-show plugins invalid

	assert_failure
	assert_output --partial "unsupported describe mode"
	refute_output --partial "gaudi-shell allows you to easily enable/disable components:"
}

@test "gaudi-shell core: gshell fails for an unknown command and for no command" {
	run gshell frobnicate
	assert_failure
	assert_output --partial "unknown command 'frobnicate'"
	assert_output --partial "Run 'gshell help' for details."

	run gshell
	assert_failure
	assert_output --partial "Usage: gshell <command> [args]"
}

@test "gaudi-shell core: gshell enable reports failure when one of several components does not exist" {
	run gshell enable alias general no-such-alias git
	assert_failure
	# The ones that exist are still enabled
	assert_file_exist "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/150___git.aliases.bash"

	run gshell disable alias general
	assert_success
	run gshell disable alias general
	assert_failure
}

@test "gaudi-shell core: gshell restore fails when there is no backup" {
	run gshell restore
	assert_failure
	assert_output --partial "No valid backup file found"
}

@test "gaudi-shell core: gshell version prints the tag and the commit, and leaves the directory alone" {
	load_gaudi_libs colors
	GAUDI_SHELL_CURRENT="bash"
	(
		cd "$GAUDI_SHELL" || exit 1
		git init -q .
		git add -A
		git commit -q -m "one"
		git tag v9.9.9
	) >/dev/null 2>&1
	mkdir -p "$BATS_TEST_TMPDIR/elsewhere" "$BATS_TEST_TMPDIR/before"
	cd "$BATS_TEST_TMPDIR/before"
	cd "$BATS_TEST_TMPDIR/elsewhere"

	gshell version >"$BATS_TEST_TMPDIR/out" 2>&1

	assert_equal "$PWD" "$BATS_TEST_TMPDIR/elsewhere"
	assert_equal "$OLDPWD" "$BATS_TEST_TMPDIR/before"
	run cat "$BATS_TEST_TMPDIR/out"
	assert_line "gaudi-shell (bash)"
	assert_line --partial "Version: "
	assert_line --partial "v9.9.9"
	assert_line --regexp "SHA: .*[0-9a-f]{7} on "
}

# A shell profile that only says it was sourced.
_write_reload_profile() {
	GAUDI_SHELL_PROFILE=".gaudi-shell-reload-test"
	echo 'echo "profile was sourced"' >"$HOME/$GAUDI_SHELL_PROFILE"
}

@test "gaudi-shell core: gshell reload sources the shell profile, and fails without one" {
	_write_reload_profile

	run gshell reload
	assert_success
	assert_line "profile was sourced"
	assert_line "gaudi-shell reloaded from $HOME/$GAUDI_SHELL_PROFILE"

	rm -f "$HOME/$GAUDI_SHELL_PROFILE"
	run gshell reload
	assert_failure
	assert_output --partial "Profile not found"
}

@test "gaudi-shell core: the automatic reload happens once per gshell command" {
	_write_reload_profile

	# Off unless asked for
	run gshell enable alias general git
	assert_success
	refute_output --partial "profile was sourced"

	GAUDI_SHELL_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE=true
	run gshell enable plugin base git
	assert_success
	assert_equal "$(grep -c "profile was sourced" <<<"$output")" "1"

	run gshell disable alias all
	assert_equal "$(grep -c "profile was sourced" <<<"$output")" "1"

	# Outside a gshell command it reloads at once
	run _gaudi-shell-disable plugin base
	assert_line "profile was sourced"

	rm -f "$HOME/$GAUDI_SHELL_PROFILE"
}

@test "gaudi-shell core: enable <type> all reports each component and fails only when one fails" {
	run gshell enable alias all
	assert_success
	assert_output --partial "general"
	refute_output --partial "alias: all"
	refute_output --partial "gaudi-bash"
}
