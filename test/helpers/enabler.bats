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

@test "gaudi-shell helpers: enable: should create a relative link" {
	run _gaudi-shell-enable plugins base
	assert_success

	run readlink "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
	assert_output "../plugins/base.plugins.bash"
}

@test "gaudi-shell helpers: enable: links should survive moving the install directory" {
	run _gaudi-shell-enable plugins base
	assert_success

	mv "$GAUDI_SHELL" "${GAUDI_SHELL}-moved"

	assert_file_exist "${GAUDI_SHELL}-moved/components/enabled/250___base.plugins.bash"

	mv "${GAUDI_SHELL}-moved" "$GAUDI_SHELL"
}

@test "gaudi-shell helpers: enable: should replace a dangling link instead of reporting it as enabled" {
	ln -s "/nonexistent/gaudi-shell/components/plugins/base.plugins.bash" "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
	# A leftover link with another priority must go as well
	ln -s "/nonexistent/gaudi-shell/components/plugins/base.plugins.bash" "$GAUDI_SHELL/components/enabled/300___base.plugins.bash"

	run _gaudi-shell-enable plugins base
	assert_success
	refute_output --partial "already enabled"
	assert_output --partial "enabled with priority"

	assert_file_exist "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
	assert_link_not_exist "$GAUDI_SHELL/components/enabled/300___base.plugins.bash"
}

@test "gaudi-shell helpers: enable: a dangling link should not be listed as enabled" {
	ln -s "/nonexistent/gaudi-shell/components/plugins/base.plugins.bash" "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"

	run _gaudi-shell-describe plugins enabled
	assert_success
	refute_output --partial "◉"

	run _gaudi-shell-enabled-link base.plugins.bash
	assert_failure
}

@test "gaudi-shell helpers: enable: should fail when the link cannot be created" {
	[[ $EUID -eq 0 ]] && skip "root can write to a read-only directory"

	chmod a-w "$GAUDI_SHELL/components/enabled"

	run _gaudi-shell-enable plugins base
	chmod u+w "$GAUDI_SHELL/components/enabled"

	assert_failure
	assert_output --partial "Failed to enable"
	refute_output --partial "enabled with priority"
	assert_link_not_exist "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
}
