#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

# Every test gets its own home directory and runs the script as a separate
# process, so nothing outside the test directory can be touched.
local_setup() {
	FAKE_HOME="$BATS_TEST_TMPDIR/home"
	mkdir -p "$FAKE_HOME"
	unset GAUDI_SHELL_PROFILE
}

# Runs uninstall.sh against the fake home. Arguments are extra NAME=value
# pairs for its environment.
_uninstall() {
	run env -u GAUDI_SHELL_PROFILE HOME="$FAKE_HOME" GAUDI_SHELL="$GAUDI_SHELL" "$@" bash "$GAUDI_SHELL/uninstall.sh"
}

# A config file the way a user has it after setup.sh appended its block.
_write_config() {
	cat >"$FAKE_HOME/$1" <<CONFIG
# my settings
export EDITOR=vim
alias ll='ls -l'

# gaudi-shell
export GAUDI_SHELL="$GAUDI_SHELL"
source "\$GAUDI_SHELL/adapters/zsh/init.zsh"

# added after gaudi-shell was installed
export PATH="\$HOME/bin:\$PATH"
CONFIG
}

@test "gaudi-shell uninstall: verify that the uninstall script exists" {

	assert_file_exist "$GAUDI_SHELL/uninstall.sh"
}

@test "gaudi-shell uninstall: removes only the gaudi-shell lines from the config file" {
	_write_config .zshrc

	_uninstall GAUDI_SHELL_PROFILE=.zshrc
	assert_success

	run cat "$FAKE_HOME/.zshrc"
	assert_line "# my settings"
	assert_line "export EDITOR=vim"
	assert_line "alias ll='ls -l'"
	assert_line "# added after gaudi-shell was installed"
	# shellcheck disable=SC2016
	assert_line 'export PATH="$HOME/bin:$PATH"'
	refute_line "# gaudi-shell"
	refute_output --partial "GAUDI_SHELL"
	refute_output --partial "adapters/"
	# The empty line setup put in front of its block went with it
	assert_equal "${#lines[@]}" "5"

	# The file was edited in place, never moved aside
	assert_file_not_exist "$FAKE_HOME/.zshrc.uninstall"
	# A copy of the file as it was is kept
	run grep -c "adapters/zsh/init.zsh" "$FAKE_HOME/.zshrc.before-gaudi-uninstall"
	assert_output "1"

	assert_dir_not_exist "$GAUDI_SHELL"
}

@test "gaudi-shell uninstall: finds the config file by itself when GAUDI_SHELL_PROFILE is not set" {
	_write_config .zshrc
	echo "export EDITOR=nano" >"$FAKE_HOME/.bashrc"

	_uninstall
	assert_success

	run grep -c "GAUDI_SHELL" "$FAKE_HOME/.zshrc"
	assert_output "0"
	# A config file that does not load gaudi-shell is not touched
	run cat "$FAKE_HOME/.bashrc"
	assert_output "export EDITOR=nano"
	assert_file_not_exist "$FAKE_HOME/.bashrc.before-gaudi-uninstall"
	assert_dir_not_exist "$GAUDI_SHELL"
}

@test "gaudi-shell uninstall: fails fast and changes nothing when the config file cannot be determined" {
	echo "export EDITOR=nano" >"$FAKE_HOME/.zshrc"

	_uninstall
	assert_failure
	assert_output --partial "could not tell which shell config file"
	assert_output --partial "Nothing was changed"

	run cat "$FAKE_HOME/.zshrc"
	assert_output "export EDITOR=nano"
	assert_dir_exist "$GAUDI_SHELL"
	assert_file_exist "$GAUDI_SHELL/gaudi_shell.sh"
	run ls -A "$FAKE_HOME"
	assert_output ".zshrc"
}

@test "gaudi-shell uninstall: an install-time backup is left alone and changes made since are kept" {
	_write_config .zshrc
	echo "the config file before gaudi-shell was installed" >"$FAKE_HOME/.zshrc.bak"

	_uninstall GAUDI_SHELL_PROFILE=.zshrc
	assert_success
	assert_output --partial ".zshrc.bak"

	run cat "$FAKE_HOME/.zshrc.bak"
	assert_output "the config file before gaudi-shell was installed"
	run cat "$FAKE_HOME/.zshrc"
	assert_line "# added after gaudi-shell was installed"
}

@test "gaudi-shell uninstall: settings the user added around the block are kept and pointed out" {
	cat >"$FAKE_HOME/.zshrc" <<CONFIG
export GAUDI_SHELL="$GAUDI_SHELL"
export GAUDI_SHELL_THEME="gaudi"
source "\$GAUDI_SHELL/adapters/zsh/init.zsh"
CONFIG

	_uninstall GAUDI_SHELL_PROFILE=.zshrc
	assert_success
	assert_output --partial "still has lines that mention GAUDI_SHELL"

	run cat "$FAKE_HOME/.zshrc"
	assert_output 'export GAUDI_SHELL_THEME="gaudi"'
}

@test "gaudi-shell uninstall: a symlinked config file stays a symlink" {
	mkdir -p "$FAKE_HOME/dotfiles"
	_write_config dotfiles/zshrc
	ln -s dotfiles/zshrc "$FAKE_HOME/.zshrc"

	_uninstall GAUDI_SHELL_PROFILE=.zshrc
	assert_success

	assert_link_exist "$FAKE_HOME/.zshrc"
	run grep -c "GAUDI_SHELL" "$FAKE_HOME/dotfiles/zshrc"
	assert_output "0"
}

@test "gaudi-shell uninstall: refuses to delete a directory that is not a gaudi-shell install" {
	_write_config .zshrc
	mkdir -p "$BATS_TEST_TMPDIR/precious"
	echo "keep me" >"$BATS_TEST_TMPDIR/precious/file"

	run env HOME="$FAKE_HOME" GAUDI_SHELL="$BATS_TEST_TMPDIR/precious" GAUDI_SHELL_PROFILE=.zshrc bash "$GAUDI_SHELL/uninstall.sh"
	assert_failure
	assert_output --partial "does not look like a gaudi-shell install"

	assert_file_exist "$BATS_TEST_TMPDIR/precious/file"
	run grep -c "GAUDI_SHELL" "$FAKE_HOME/.zshrc"
	assert_output "2"
}

@test "gaudi-shell uninstall: the bash config written by setup is cleaned too" {
	run env HOME="$FAKE_HOME" SHELL=/bin/bash "$GAUDI_SHELL/setup.sh" --silent --shell bash
	local config=".bashrc"
	[[ "$OSTYPE" == darwin* ]] && config=".bash_profile"
	run grep -c "adapters/bash/init.bash" "$FAKE_HOME/$config"
	assert_output "1"

	_uninstall
	assert_success

	run grep -c "GAUDI_SHELL\|gaudi-shell" "$FAKE_HOME/$config"
	assert_output "0"
	assert_dir_not_exist "$GAUDI_SHELL"
}
