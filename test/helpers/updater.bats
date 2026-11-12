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

# --- the shared components (git submodules) ---

# Local stand-ins for the shared repositories and for the release that turns
# components/aliases into a submodule: nothing here uses the network.
#
# Before: the install is at v0.0.1, where components/aliases holds plain files
# (the old, vendored layout: general.aliases.bash right in the folder).
# After:  v0.0.2 on the remote has components/aliases as a submodule of a
# local repository that keeps the same file under lib/.
_publish_components_as_submodule() {
	(
		# git refuses file:// submodules unless told otherwise (HOME is the suite's)
		git config --global protocol.file.allow always

		cd "$GAUDI_SHELL" || exit 1
		mv components/aliases/lib "$BATS_TEST_TMPDIR/aliases-lib"
		rm -rf components/aliases
		mkdir components/aliases
		cp "$BATS_TEST_TMPDIR/aliases-lib"/*.bash components/aliases/
		git init -q .
		git add -A
		_commit_dated 2020-01-01 -m "one"
		git tag v0.0.1
		git clone -q --bare . "$BATS_TEST_TMPDIR/remote.git"
		git remote add origin "$BATS_TEST_TMPDIR/remote.git"

		mkdir -p "$BATS_TEST_TMPDIR/shared-aliases"
		cd "$BATS_TEST_TMPDIR/shared-aliases" || exit 1
		mv "$BATS_TEST_TMPDIR/aliases-lib" lib
		git init -q .
		git add -A
		_commit_dated 2020-06-01 -m "shared aliases"

		git clone -q "$BATS_TEST_TMPDIR/remote.git" "$BATS_TEST_TMPDIR/other"
		cd "$BATS_TEST_TMPDIR/other" || exit 1
		git rm -r -q components/aliases
		git submodule add -q "$BATS_TEST_TMPDIR/shared-aliases" components/aliases
		_commit_dated 2021-01-01 -m "two: aliases become a submodule"
		git tag v0.0.2
		git push -q origin HEAD --tags
	) >/dev/null 2>&1
}

@test "gaudi-shell helpers: update: fetches the component submodules and migrates the enabled links after the checkout" {
	_publish_components_as_submodule
	assert_file_exist "$GAUDI_SHELL/components/aliases/general.aliases.bash"
	# Enabled the way the old layout did it
	ln -s "../aliases/general.aliases.bash" "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	ln -s "../completions/gaudi-shell.completions.bash" "$GAUDI_SHELL/components/enabled/350___gaudi-shell.completions.bash"
	cd "$ELSEWHERE"

	_gaudi-shell-update --silent >"$BATS_TEST_TMPDIR/out" 2>&1 </dev/null

	run cat "$BATS_TEST_TMPDIR/out"
	assert_output --partial "successfully updated"
	assert_line "migrated 150___general.aliases.bash -> ../aliases/lib/general.aliases.bash"
	assert_line "migrated 350___gaudi-shell.completions.bash -> ../host/gaudi-shell.completions.bash"
	assert_output --partial "RESTART"
	assert_equal "$(git -C "$GAUDI_SHELL" describe --tags)" "v0.0.2"

	# The submodule was checked out at the pinned commit ...
	assert_file_exist "$GAUDI_SHELL/components/aliases/lib/general.aliases.bash"
	assert_file_not_exist "$GAUDI_SHELL/components/aliases/general.aliases.bash"
	assert_equal "$(git -C "$GAUDI_SHELL/components/aliases" rev-parse HEAD)" "$(git -C "$BATS_TEST_TMPDIR/shared-aliases" rev-parse HEAD)"
	# ... and the links work again, with the priority they had
	run readlink "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	assert_output "../aliases/lib/general.aliases.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/350___gaudi-shell.completions.bash"
	assert_equal "$PWD" "$ELSEWHERE"
	assert_equal "$(_directory_stack_depth)" "1"
}

@test "gaudi-shell helpers: update: a component submodule on another commit is not a local change" {
	_publish_components_as_submodule
	_gaudi-shell-update --silent >/dev/null 2>&1 </dev/null
	# The shared repository moves on and the install follows it by hand
	(
		cd "$BATS_TEST_TMPDIR/shared-aliases" || exit 1
		_commit_dated 2021-06-01 --allow-empty -m "newer shared aliases"
		git -C "$GAUDI_SHELL/components/aliases" fetch -q origin
		git -C "$GAUDI_SHELL/components/aliases" checkout -q FETCH_HEAD
	) >/dev/null 2>&1
	run git -C "$GAUDI_SHELL" diff --name-status
	assert_output --partial "components/aliases"
	cd "$ELSEWHERE"

	local status_code=0
	_gaudi-shell-update >"$BATS_TEST_TMPDIR/out" 2>&1 </dev/null || status_code=$?

	run cat "$BATS_TEST_TMPDIR/out"
	refute_output --partial "Local changes detected"
	assert_output --partial "latest stable version"
	assert_equal "$status_code" "0"
}

@test "gaudi-shell helpers: update: when already up to date it still fetches missing components and migrates old links" {
	_publish_components_as_submodule
	# Updated by hand: the new version is checked out, the submodule is not
	git -C "$GAUDI_SHELL" fetch -q origin --tags
	git -C "$GAUDI_SHELL" checkout -q v0.0.2
	assert_file_not_exist "$GAUDI_SHELL/components/aliases/lib/general.aliases.bash"
	ln -s "../aliases/general.aliases.bash" "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	cd "$ELSEWHERE"

	_gaudi-shell-update >"$BATS_TEST_TMPDIR/out" 2>&1 </dev/null

	run cat "$BATS_TEST_TMPDIR/out"
	assert_output --partial "latest stable version"
	assert_line "migrated 150___general.aliases.bash -> ../aliases/lib/general.aliases.bash"
	refute_output --partial "RESTART"
	assert_file_exist "$GAUDI_SHELL/components/aliases/lib/general.aliases.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	assert_equal "$PWD" "$ELSEWHERE"
	assert_equal "$(_directory_stack_depth)" "1"
}

@test "gaudi-shell helpers: update: says how to fetch the components when that fails, and still updates" {
	_publish_components_as_submodule
	# The shared repository cannot be reached
	mv "$BATS_TEST_TMPDIR/shared-aliases" "$BATS_TEST_TMPDIR/shared-aliases-gone"
	cd "$ELSEWHERE"

	_gaudi-shell-update --silent >"$BATS_TEST_TMPDIR/out" 2>&1 </dev/null

	run cat "$BATS_TEST_TMPDIR/out"
	assert_output --partial "Could not update the shared components"
	assert_output --partial "git -C \"$GAUDI_SHELL\" submodule update --init components/aliases components/completions components/plugins"
	assert_output --partial "RESTART"
	assert_equal "$(git -C "$GAUDI_SHELL" describe --tags)" "v0.0.2"
}

@test "gaudi-shell helpers: update: dev moves to the tip of the development branch" {
	_make_install_a_checkout
	_publish_newer_tag
	# Whatever git calls the first branch here
	GAUDI_SHELL_DEVELOPMENT_BRANCH="$(git -C "$GAUDI_SHELL" symbolic-ref --short HEAD)"
	cd "$ELSEWHERE"

	_gaudi-shell-update dev --silent >"$BATS_TEST_TMPDIR/out" 2>&1 </dev/null

	run cat "$BATS_TEST_TMPDIR/out"
	assert_output --partial "Updating to origin/${GAUDI_SHELL_DEVELOPMENT_BRANCH}"
	assert_output --partial "successfully updated"
	assert_output --partial "RESTART"
	assert_equal "$(git -C "$GAUDI_SHELL" rev-parse HEAD)" "$(git -C "$BATS_TEST_TMPDIR/remote.git" rev-parse "$GAUDI_SHELL_DEVELOPMENT_BRANCH")"
	assert_equal "$PWD" "$ELSEWHERE"
	assert_equal "$(_directory_stack_depth)" "1"
}

@test "gaudi-shell helpers: update: a checkout ahead of the latest tag is offered the way back to it" {
	_make_install_a_checkout
	(
		cd "$GAUDI_SHELL" || exit 1
		_commit_dated 2021-01-01 --allow-empty -m "local work"
	) >/dev/null 2>&1
	cd "$ELSEWHERE"

	_gaudi-shell-update >"$BATS_TEST_TMPDIR/out" 2>&1 <<<"n"

	run cat "$BATS_TEST_TMPDIR/out"
	assert_output --partial "more recent development version"
	assert_output --partial "local work"
	assert_output --partial "Would you like to update to v0.0.1"
	assert_output --partial "Not updating"
	refute_output --partial "RESTART"
	assert_equal "$(_directory_stack_depth)" "1"
}
