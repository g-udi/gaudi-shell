#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs log gaudi-shell
}

@test "gaudi-shell core: _gaudi-shell-restore should reject invalid backup entries" {

	cd "$GAUDI_SHELL"
	./setup.sh --silent --shell bash

	mkdir -p "$GAUDI_SHELL/tmp"

	# Write a backup file with a mix of valid and invalid entries
	cat >"$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup" <<'BACKUP'
gshell enable plugin base
echo INJECTED
gshell enable alias general
rm -rf /tmp/should-not-run
BACKUP

	# Disable everything first
	run gshell disable plugins all
	run gshell disable aliases all
	run gshell disable completion all

	# Restore should only process valid lines
	run _gaudi-shell-restore
	assert_success

	# Valid components should be restored
	assert_file_exist "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"

	# Invalid commands should NOT have created any side effects
	# (the "echo INJECTED" and "rm -rf" lines should have been skipped)
	refute_output --partial "INJECTED"
}

@test "gaudi-shell core: _gaudi-shell-restore should accept all valid component types" {

	cd "$GAUDI_SHELL"
	./setup.sh --silent --shell bash

	mkdir -p "$GAUDI_SHELL/tmp"

	cat >"$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup" <<'BACKUP'
gshell enable plugin base
gaudi enable alias general
gshell enable completion gaudi-shell
BACKUP

	run gshell disable plugins all
	run gshell disable aliases all
	run gshell disable completion all

	run _gaudi-shell-restore
	assert_success

	assert_file_exist "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/350___gaudi-shell.completions.bash"
}

@test "gaudi-shell core: _gaudi-shell-restore should fail gracefully with no backup file" {

	cd "$GAUDI_SHELL"
	./setup.sh --silent --shell bash

	rm -f "$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup"

	run _gaudi-shell-restore
	assert_output --partial "No valid backup file found"
}
