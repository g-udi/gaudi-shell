#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	if command -v rsync &>/dev/null; then
		rsync -a "$GAUDI_SHELL/test/fixtures/gaudi_shell/" "$GAUDI_SHELL/components"
	else
		find "$GAUDI_SHELL/test/fixtures/gaudi_shell" \
			-mindepth 1 -maxdepth 1 \
			-exec cp -r {} "$GAUDI_SHELL/components/" \;
	fi
}

@test "gaudi-shell loader: load aliases in order" {
	ln -s "$GAUDI_SHELL/components/aliases/a.aliases.bash" "$GAUDI_SHELL/components/enabled/150___a.aliases.bash"
	ln -s "$GAUDI_SHELL/components/aliases/b.aliases.bash" "$GAUDI_SHELL/components/enabled/150___b.aliases.bash"

	run alias test_alias &>/dev/null
	assert_failure

	load "$GAUDI_SHELL/gaudi_shell.sh"

	run alias test_alias &>/dev/null
	assert_success
	assert_line --index 0 "alias test_alias='b'"
}

@test "gaudi-shell loader: load aliases in priority order" {
	ln -s "$GAUDI_SHELL/components/aliases/a.aliases.bash" "$GAUDI_SHELL/components/enabled/175___a.aliases.bash"
	ln -s "$GAUDI_SHELL/components/aliases/b.aliases.bash" "$GAUDI_SHELL/components/enabled/150___b.aliases.bash"

	load "$GAUDI_SHELL/gaudi_shell.sh"

	run alias test_alias &>/dev/null
	assert_success
	assert_line --index 0 "alias test_alias='a'"
}

@test "gaudi-shell loader: finalize hooks should run after all components loaded" {
	ln -s "$GAUDI_SHELL/components/plugins/d.plugins.bash" "$GAUDI_SHELL/components/enabled/250___d.plugins.bash"

	load "$GAUDI_SHELL/gaudi_shell.sh"

	run alias test_finalize_hook &>/dev/null
	assert_success
	assert [ "${GAUDI_FINALIZE_HOOK_RAN}" == "true" ]
}

@test "gaudi-shell loader: load local custom scripts from multiple custom paths" {
	local custom_one custom_two
	custom_one="${BATS_TEST_TMPDIR}/custom-one"
	custom_two="${BATS_TEST_TMPDIR}/custom-two"
	mkdir -p "$custom_one" "$custom_two"

	cat >"$custom_one/100-local.aliases.bash" <<'CUSTOM'
alias local_custom_one='echo one'
CUSTOM

	cat >"$custom_two/200-local.aliases.bash" <<'CUSTOM'
alias local_custom_two='echo two'
CUSTOM

	export GAUDI_SHELL_CUSTOM_PATHS="${custom_one}:${custom_two}"

	run alias local_custom_one &>/dev/null
	assert_failure
	run alias local_custom_two &>/dev/null
	assert_failure

	load "$GAUDI_SHELL/gaudi_shell.sh"

	run alias local_custom_one &>/dev/null
	assert_success
	assert_line --index 0 "alias local_custom_one='echo one'"

	run alias local_custom_two &>/dev/null
	assert_success
	assert_line --index 0 "alias local_custom_two='echo two'"
}
