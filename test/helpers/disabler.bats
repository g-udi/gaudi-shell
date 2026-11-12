#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs gaudi-shell cache components utils disabler
}

@test "gaudi-shell helpers: _gaudi-shell-disable: should fail if no valid component type was passed" {

	run _gaudi-shell-disable
	assert_failure
	assert_output --partial "Please enter a valid component to disable"
}

@test "gaudi-shell helpers: _gaudi-shell-disable: should fail if no valid component was passed" {

	run _gaudi-shell-disable plugin
	assert_failure
	assert_output --partial "Please enter a valid"
	assert_output --partial "to disable"
}

@test "gaudi-shell helpers: _gaudi-shell-disable: should fail if component was not found" {

	run _gaudi-shell-disable plugin INVALID
	assert_failure
	assert_output --partial "INVALID"
	assert_output --partial "does not appear to be an enabled"
}

@test "gaudi-shell helpers: _gaudi-shell-disable: should successfully disable a component" {

	run _gaudi-shell-disable plugin go
	assert_failure
	assert_output --partial "does not appear to be an enabled"
	assert_file_not_exist "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
}

@test "gaudi-shell helpers: _gaudi-shell-disable: should display appropriate message when trying to disable an already disabled component" {
	run _gaudi-shell-enable plugin node
	assert_success
	assert_file_exist "$GAUDI_SHELL/components/enabled/250___node.plugins.bash"

	run _gaudi-shell-disable plugin node
	assert_output --partial "disabled"
	assert_file_not_exist "$GAUDI_SHELL/components/enabled/250___node.plugins.bash"
}

@test "gaudi-shell helpers: _gaudi-shell-disable: should run the component disable function if it exists" {

	# shellcheck disable=SC2329
	git_on_disable() {
		echo "callback"
	}

	run _gaudi-shell-enable plugin git
	assert_success
	assert_file_exist "$GAUDI_SHELL/components/enabled/250___git.plugins.bash"

	run _gaudi-shell-disable plugin git
	assert_output --partial "disabled"
	assert_output --partial "callback"
	assert_file_not_exist "$GAUDI_SHELL/components/enabled/250___git.plugins.bash"
}

@test "gaudi-shell helpers: _gaudi-shell-disable: should disable multiple components passed" {

	run gshell enable plugin "nvm" "node"
	assert_line --index 0 --partial "enabled with priority"
	assert_line --index 1 --partial "enabled with priority"

	assert_link_exist "$GAUDI_SHELL/components/enabled/250___node.plugins.bash"
	assert_link_exist "$GAUDI_SHELL/components/enabled/250___nvm.plugins.bash"

	run gshell disable plugin "nvm" "node"
	assert_link_not_exist "$GAUDI_SHELL/components/enabled/250___node.plugins.bash"
	assert_link_not_exist "$GAUDI_SHELL/components/enabled/250___nvm.plugins.bash"
}

@test "gaudi-shell helpers: _gaudi-shell-disable: should disable all plugins" {

	local available enabled

	run _gaudi-shell-enable plugins "all"
	available=$(find "$GAUDI_SHELL/components/plugins" -name "*.plugins.bash" | wc -l | xargs)
	enabled=$(find "$GAUDI_SHELL/components/enabled" -name "[0-9]*.plugins.bash" | wc -l | xargs)
	assert_equal "$available" "$enabled"

	run _gaudi-shell-enable alias "ag"
	assert_file_exist "$GAUDI_SHELL/components/enabled/150___ag.aliases.bash"

	run _gaudi-shell-disable plugins "all"
	enabled=$(find "$GAUDI_SHELL/components/enabled" -name "[0-9]*.plugins.bash" | wc -l | xargs)
	assert_equal "0" "$enabled"
	assert_link_exist "$GAUDI_SHELL/components/enabled/150___ag.aliases.bash"
}

@test "gaudi-shell helpers: _gaudi-shell-disable: should disable all plugins with priority" {

	local enabled

	run gshell enable plugin "nvm"
	assert_file_exist "$GAUDI_SHELL/components/enabled/250___nvm.plugins.bash"

	run gshell enable plugin "node"
	assert_file_exist "$GAUDI_SHELL/components/enabled/250___node.plugins.bash"

	enabled=$(find "$GAUDI_SHELL/components/enabled" -name "*.plugins.bash" | wc -l | xargs)
	assert_equal "2" "$enabled"

	run _gaudi-shell-enable alias "ag"
	assert_file_exist "$GAUDI_SHELL/components/enabled/150___ag.aliases.bash"

	run _gaudi-shell-disable plugins "all"
	enabled=$(find "$GAUDI_SHELL/components/enabled" -name "*.plugins.bash" | wc -l | xargs)
	assert_equal "0" "$enabled"
	assert_file_exist "$GAUDI_SHELL/components/enabled/150___ag.aliases.bash"
}

@test "gaudi-shell helpers: _gaudi-shell-enable: should handle properly disabling a set of mixed existing and non-existing components" {
	run gshell enable plugin "node"
	assert_line --index 0 -p "enabled with priority"

	run gshell disable plugin node INVALID nvm
	assert_line --index 0 -p "disabled"
	assert_line --index 1 -p "does not appear to be an enabled"
	assert_line --index 2 -p "does not appear to be an enabled"

	assert_link_not_exist "$GAUDI_SHELL/components/enabled/250___node.plugins.bash"
	assert_link_not_exist "$GAUDI_SHELL/components/enabled/250___nvm.plugins.bash"
}

@test "gaudi-shell helpers: _gaudi-shell-disable: disabling all plugins runs the disable function of each one" {
	# Called by name from _on-disable-callback
	# shellcheck disable=SC2329
	git_on_disable() {
		echo "git callback"
	}
	# shellcheck disable=SC2329
	base_on_disable() {
		echo "base callback"
	}
	run gshell enable plugin git base
	assert_success

	run _gaudi-shell-disable plugins all
	assert_success
	assert_line "git callback"
	assert_line "base callback"
}

@test "gaudi-shell helpers: _gaudi-shell-disable: disabling all without an enabled folder prints no error" {
	rm -rf "$GAUDI_SHELL/components/enabled"

	run _gaudi-shell-disable aliases all
	assert_success
	refute_output --partial "No such file"
	assert_output --partial "disabled"
}
