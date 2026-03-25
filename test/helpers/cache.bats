#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs components cache
}

@test "gaudi-shell helpers: cache: should fail if no component type passed" {
	run _gaudi-shell-component-cache-add
	assert_failure
}

@test "gaudi-shell helpers: cache: should return cache file path" {
	run _gaudi-shell-component-cache-add plugins
	assert_success
	assert_output "$GAUDI_SHELL_CACHE_DIR/plugins"
}

@test "gaudi-shell helpers: cache: should create cache directory" {
	run _gaudi-shell-component-cache-add plugins
	assert_success
	assert_dir_exist "$GAUDI_SHELL_CACHE_DIR"
}

@test "gaudi-shell helpers: cache: clean should remove cache files" {
	_plugins_cache=$(_gaudi-shell-component-cache-add plugins)
	_aliases_cache=$(_gaudi-shell-component-cache-add aliases)
	touch "${_plugins_cache}" "${_aliases_cache}"

	assert_file_exist "$GAUDI_SHELL_CACHE_DIR/plugins"
	assert_file_exist "$GAUDI_SHELL_CACHE_DIR/aliases"

	_gaudi-shell-component-cache-clean

	assert_file_not_exist "$GAUDI_SHELL_CACHE_DIR/plugins"
	assert_file_not_exist "$GAUDI_SHELL_CACHE_DIR/aliases"
}
