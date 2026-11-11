#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs log colors composure gaudi-shell

	# Never re-exec the shell that runs the tests
	# shellcheck disable=SC2329
	_gaudi-shell-restart() {
		echo "RESTART"
	}

	ELSEWHERE="$BATS_TEST_TMPDIR/elsewhere"
	mkdir -p "$ELSEWHERE"
}

# Turns the test copy into a git checkout at tag v0.0.1 whose "origin" remote
# is a local bare repository.
_make_install_a_checkout() {
	(
		cd "$GAUDI_SHELL" || exit 1
		git init -q .
		git add -A
		_commit_dated 2020-01-01 -m "one"
		git tag v0.0.1
		git clone -q --bare . "$BATS_TEST_TMPDIR/remote.git"
		git remote add origin "$BATS_TEST_TMPDIR/remote.git"
	) >/dev/null 2>&1
}

# Publishes a newer tag (v0.0.2) on the remote.
_publish_newer_tag() {
	(
		git clone -q "$BATS_TEST_TMPDIR/remote.git" "$BATS_TEST_TMPDIR/other"
		cd "$BATS_TEST_TMPDIR/other" || exit 1
		_commit_dated 2021-01-01 --allow-empty -m "two"
		git tag v0.0.2
		git push -q origin HEAD --tags
	) >/dev/null 2>&1
}

# Commits with explicit, increasing dates: the updater picks the tag of the
# most recent commit, and commits made within one second would tie.
_commit_dated() {
	GIT_AUTHOR_DATE="$1T12:00:00Z" GIT_COMMITTER_DATE="$1T12:00:00Z" git commit -q "${@:2}"
}

_directory_stack_depth() {
	dirs -p | wc -l | tr -d ' '
}

@test "gaudi-shell helpers: update: reports the latest stable version and stays in the current directory" {
	_make_install_a_checkout
	cd "$ELSEWHERE"

	_gaudi-shell-update >"$BATS_TEST_TMPDIR/out" 2>&1 </dev/null

	run cat "$BATS_TEST_TMPDIR/out"
	assert_output --partial "latest stable version"
	assert_equal "$PWD" "$ELSEWHERE"
	assert_equal "$(_directory_stack_depth)" "1"
}

@test "gaudi-shell helpers: update: declining an update leaves the checkout and the directory alone" {
	_make_install_a_checkout
	_publish_newer_tag
	cd "$ELSEWHERE"

	_gaudi-shell-update >"$BATS_TEST_TMPDIR/out" 2>&1 <<<"n"

	run cat "$BATS_TEST_TMPDIR/out"
	assert_output --partial "Would you like to update to v0.0.2"
	assert_output --partial "Not updating"
	refute_output --partial "RESTART"
	assert_equal "$PWD" "$ELSEWHERE"
	assert_equal "$(_directory_stack_depth)" "1"
	assert_equal "$(git -C "$GAUDI_SHELL" describe --tags)" "v0.0.1"
}

@test "gaudi-shell helpers: update: no answer is not taken as a yes" {
	_make_install_a_checkout
	_publish_newer_tag
	cd "$ELSEWHERE"

	_gaudi-shell-update >"$BATS_TEST_TMPDIR/out" 2>&1 </dev/null

	run cat "$BATS_TEST_TMPDIR/out"
	refute_output --partial "RESTART"
	assert_equal "$PWD" "$ELSEWHERE"
	assert_equal "$(git -C "$GAUDI_SHELL" describe --tags)" "v0.0.1"
}

@test "gaudi-shell helpers: update: accepting an update checks out the tag and pops the directory" {
	_make_install_a_checkout
	_publish_newer_tag
	cd "$ELSEWHERE"

	_gaudi-shell-update >"$BATS_TEST_TMPDIR/out" 2>&1 <<<"y"

	run cat "$BATS_TEST_TMPDIR/out"
	assert_output --partial "successfully updated"
	assert_output --partial "RESTART"
	assert_equal "$PWD" "$ELSEWHERE"
	assert_equal "$(_directory_stack_depth)" "1"
	assert_equal "$(git -C "$GAUDI_SHELL" describe --tags)" "v0.0.2"
}

@test "gaudi-shell helpers: update: a failed checkout fails and still pops the directory" {
	_make_install_a_checkout
	_publish_newer_tag
	# An untracked file that the new tag would overwrite makes the checkout fail
	(
		cd "$BATS_TEST_TMPDIR/other" || exit 1
		echo "theirs" >blocker.txt
		git add blocker.txt
		_commit_dated 2022-01-01 -m "three"
		git tag v0.0.3
		git push -q origin HEAD --tags
	) >/dev/null 2>&1
	echo "mine" >"$GAUDI_SHELL/blocker.txt"
	cd "$ELSEWHERE"

	local status_code=0
	_gaudi-shell-update --silent >"$BATS_TEST_TMPDIR/out" 2>&1 || status_code=$?

	run cat "$BATS_TEST_TMPDIR/out"
	assert_output --partial "Error updating gaudi-shell"
	refute_output --partial "RESTART"
	assert_equal "$status_code" "1"
	assert_equal "$PWD" "$ELSEWHERE"
	assert_equal "$(_directory_stack_depth)" "1"
}

@test "gaudi-shell helpers: update: local changes stop the update and pop the directory" {
	_make_install_a_checkout
	echo "# changed" >>"$GAUDI_SHELL/setup.sh"
	cd "$ELSEWHERE"

	local status_code=0
	_gaudi-shell-update >"$BATS_TEST_TMPDIR/out" 2>&1 </dev/null || status_code=$?

	run cat "$BATS_TEST_TMPDIR/out"
	assert_output --partial "Local changes detected"
	assert_equal "$status_code" "1"
	assert_equal "$PWD" "$ELSEWHERE"
	assert_equal "$(_directory_stack_depth)" "1"
}

@test "gaudi-shell helpers: update: without tags it fails and pops the directory" {
	(
		cd "$GAUDI_SHELL" || exit 1
		git init -q .
		git add -A
		_commit_dated 2020-01-01 -m "one"
		git clone -q --bare . "$BATS_TEST_TMPDIR/remote.git"
		git remote add origin "$BATS_TEST_TMPDIR/remote.git"
	) >/dev/null 2>&1
	cd "$ELSEWHERE"

	local status_code=0
	_gaudi-shell-update >"$BATS_TEST_TMPDIR/out" 2>&1 </dev/null || status_code=$?

	run cat "$BATS_TEST_TMPDIR/out"
	assert_output --partial "Can not find tags"
	assert_equal "$status_code" "1"
	assert_equal "$PWD" "$ELSEWHERE"
	assert_equal "$(_directory_stack_depth)" "1"
}

@test "gaudi-shell helpers: update: a failed fetch fails and pops the directory" {
	_make_install_a_checkout
	# The remote is gone: nothing can be fetched
	git -C "$GAUDI_SHELL" remote set-url origin "$BATS_TEST_TMPDIR/no-such-remote.git"
	cd "$ELSEWHERE"

	local status_code=0
	_gaudi-shell-update --silent >"$BATS_TEST_TMPDIR/out" 2>&1 </dev/null || status_code=$?

	run cat "$BATS_TEST_TMPDIR/out"
	assert_output --partial "Could not fetch from 'origin'"
	refute_output --partial "RESTART"
	assert_equal "$status_code" "1"
	assert_equal "$PWD" "$ELSEWHERE"
	assert_equal "$(_directory_stack_depth)" "1"
}
