#!/usr/bin/env bats
# shellcheck shell=bats

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

	assert_file_not_exist "$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup"

	run _gaudi-shell-backup

	assert_file_exist "$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup"

	run cat "$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup"
	assert_success
	assert_output --partial "gaudi enable alias general"
	assert_output --partial "gaudi enable plugin base"
	assert_output --partial "gaudi enable completion system"
}

@test "gaudi-shell core: _gaudi-shell-backup should overwrite old backed up components" {

	cd "$GAUDI_SHELL"
	./setup.sh --silent --shell bash

	assert_sane_defaults

	assert_file_not_exist "$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup"

	run _gaudi-shell-backup

	assert_file_exist "$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup"

	run gaudi disable completion git
	run _gaudi-shell-backup

	assert_file_exist "$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup"
	run cat "$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup"
	assert_output --partial "gaudi enable alias general"
}

@test "gaudi-shell core: _gaudi-shell-restore should successfully restore backed up components" {

	cd "$GAUDI_SHELL"
	./setup.sh --silent --shell bash

	assert_sane_defaults

	assert_file_not_exist "$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup"

	run _gaudi-shell-backup

	assert_line --index 0 "Backing up alias: general"
	assert_file_exist "$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup"

	run gaudi disable plugins all
	run gaudi disable completion all
	run gaudi disable aliases all

	assert_file_not_exist "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	assert_file_not_exist "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
	assert_file_not_exist "$GAUDI_SHELL/components/enabled/365___alias-completion.plugins.bash"
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
