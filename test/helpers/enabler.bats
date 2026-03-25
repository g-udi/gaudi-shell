#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs log gaudi-shell components cache core utils enabler disabler
}

@test "gaudi-shell helpers: enable: should fail with no component type" {
	run _gaudi-shell-enable
	assert_failure
}

@test "gaudi-shell helpers: enable: should fail with no component name" {
	run _gaudi-shell-enable plugins
	assert_failure
}

@test "gaudi-shell helpers: enable: should fail for non-existent component" {
	run _gaudi-shell-enable plugins nonexistent
	assert_failure
}

@test "gaudi-shell helpers: enable: should successfully enable a component" {
	run _gaudi-shell-enable plugins base
	assert_success
	assert_file_exist "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
}

@test "gaudi-shell helpers: enable: should report already enabled" {
	ln -s "$GAUDI_SHELL/components/plugins/base.plugins.bash" "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"

	run _gaudi-shell-enable plugins base
	assert_success
	assert_output --partial "already enabled"
}

@test "gaudi-shell helpers: enable: should enable multiple components" {
	run _gaudi-shell-enable plugins base
	assert_success
	run _gaudi-shell-enable plugins extract
	assert_success
	assert_file_exist "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/250___extract.plugins.bash"
}

@test "gaudi-shell helpers: disable: should successfully disable a component" {
	ln -s "$GAUDI_SHELL/components/plugins/base.plugins.bash" "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"

	run _gaudi-shell-disable plugins base
	assert_success
	assert_file_not_exist "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
}

@test "gaudi-shell helpers: disable: should fail for non-enabled component" {
	run _gaudi-shell-disable plugins nonexistent
	assert_failure
}
