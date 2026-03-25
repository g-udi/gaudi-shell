#!/usr/bin/env bash
# shellcheck shell=bash

function load_gaudi_libs() {
	for lib in "$@"; do
		local component
		component=$(find "${GAUDI_SHELL}/lib" -type f -iname "${lib}.bash" 2>/dev/null | head -1)
		[[ -n "$component" ]] && load "$component"
	done
	return 0
}

function setup() {
	export GIT_CONFIG_NOSYSTEM
	export XDG_CACHE_HOME="${GAUDI_TEST_DIRECTORY?}"

	cp "$LEGACY_HOME/$GAUDI_SHELL_PROFILE" "$HOME" 2>/dev/null || true

	[[ ! -d "$GAUDI_SHELL" ]] && git --git-dir="${GAUDI_SHELL_GIT_DIR?}" worktree add -d -f "${GAUDI_SHELL}"

	# Sync test worktree
	(
		cd "${GAUDI_SHELL_ORIGIN}" &&
			tar \
				--exclude='.git' \
				--exclude='bin' \
				--exclude='components' \
				--exclude='test/gaudi-shell' \
				-cf - .
	) | (
		cd "${GAUDI_SHELL}" &&
			tar -xf -
	)

	# Clean runtime state
	rm -rf "$GAUDI_SHELL/tmp"
	mkdir -p "$GAUDI_SHELL/components/enabled"

	# Copy components from origin
	cp -r "$GAUDI_SHELL_ORIGIN/components/aliases" "$GAUDI_SHELL/components/" 2>/dev/null || true
	cp -r "$GAUDI_SHELL_ORIGIN/components/plugins" "$GAUDI_SHELL/components/" 2>/dev/null || true
	cp -r "$GAUDI_SHELL_ORIGIN/components/completions" "$GAUDI_SHELL/components/" 2>/dev/null || true

	local_setup
}

function setup_file() {
	set -a

	export GAUDI_TEST_RUNNER="enabled"
	export LEGACY_HOME=$HOME

	load "${GAUDI_TEST_DEPS_DIR}/bats-support/load.bash"
	load "${GAUDI_TEST_DEPS_DIR}/bats-assert/load.bash"
	load "${GAUDI_TEST_DEPS_DIR}/bats-file/load.bash"

	XDG_DUMMY=""
	unset "${!XDG_@}"

	readonly HOME="${BATS_SUITE_TMPDIR?}"
	mkdir -p "${HOME}"

	git config --global user.name "gaudi-shell bats runner"
	git config --global user.email "test@gaudi.shell"
}

function teardown() {
	rm -rf "${GAUDI_SHELL}/components/enabled"
	rm -rf "${GAUDI_SHELL}/tmp"
}
