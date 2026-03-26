#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	true
}

@test "gaudi-shell install: verify that the install script exists" {

	assert_file_exist "$GAUDI_SHELL/install.sh"
}

@test "gaudi-shell install: verify that the setup script exists" {

	assert_file_exist "$GAUDI_SHELL/setup.sh"
}

@test "gaudi-shell install: run the install script silently by skipping prompts" {

	run ./setup.sh --silent
	[[ -z $output ]]
}

@test "gaudi-shell install: run the install script silently and check that config file exists" {

	cd "$GAUDI_SHELL"

	./setup.sh --silent
	assert_file_exist "$HOME/$GAUDI_SHELL_PROFILE"
}

@test "gaudi-shell install: run the install script silently and enable sane defaults" {

	cd "$GAUDI_SHELL"

	./setup.sh --silent

	assert_file_exist "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/325___system.completions.bash"
}

@test "gaudi-shell install: run the install script silently and don't modify configs" {
	rm -rf "${HOME:?}/${GAUDI_SHELL_PROFILE:?}"

	cd "$GAUDI_SHELL"
	./setup.sh --silent --no_modify_config

	assert_file_not_exist "$HOME/${GAUDI_SHELL_PROFILE}"
}

@test "gaudi-shell install: verify that a backup file is created" {

	local md5_orig
	local md5_bak

	cd "$GAUDI_SHELL" || exit

	touch "$HOME/$GAUDI_SHELL_PROFILE"
	echo "test file content" > "$HOME/$GAUDI_SHELL_PROFILE"
	md5_orig=$(md5sum "$HOME/$GAUDI_SHELL_PROFILE" | awk '{print $1}')

	./setup.sh --silent

	assert_file_exist "$HOME/$GAUDI_SHELL_PROFILE"
	assert_file_exist "$HOME/$GAUDI_SHELL_PROFILE.bak"

	md5_bak=$(md5sum "$HOME/$GAUDI_SHELL_PROFILE.bak" | awk '{print $1}')

	assert_equal "$md5_orig" "$md5_bak"
}
