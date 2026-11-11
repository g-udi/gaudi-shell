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
	ln -s "$GAUDI_SHELL/components/aliases/lib/a.aliases.bash" "$GAUDI_SHELL/components/enabled/150___a.aliases.bash"
	ln -s "$GAUDI_SHELL/components/aliases/lib/b.aliases.bash" "$GAUDI_SHELL/components/enabled/150___b.aliases.bash"

	run alias test_alias &>/dev/null
	assert_failure

	load "$GAUDI_SHELL/gaudi_shell.sh"

	run alias test_alias &>/dev/null
	assert_success
	assert_line --index 0 "alias test_alias='b'"
}

@test "gaudi-shell loader: load aliases in priority order" {
	ln -s "$GAUDI_SHELL/components/aliases/lib/a.aliases.bash" "$GAUDI_SHELL/components/enabled/175___a.aliases.bash"
	ln -s "$GAUDI_SHELL/components/aliases/lib/b.aliases.bash" "$GAUDI_SHELL/components/enabled/150___b.aliases.bash"

	load "$GAUDI_SHELL/gaudi_shell.sh"

	run alias test_alias &>/dev/null
	assert_success
	assert_line --index 0 "alias test_alias='a'"
}

@test "gaudi-shell loader: finalize hooks should run after all components loaded" {
	ln -s "$GAUDI_SHELL/components/plugins/lib/d.plugins.bash" "$GAUDI_SHELL/components/enabled/250___d.plugins.bash"

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

@test "gaudi-shell loader: a dangling link is reported with the command that repairs it" {
	ln -s "/nonexistent/gaudi-shell/components/aliases/gone.aliases.bash" "$GAUDI_SHELL/components/enabled/150___gone.aliases.bash"
	ln -s "/nonexistent/gaudi-shell/components/plugins/alias-completion.plugins.bash" "$GAUDI_SHELL/components/enabled/365___alias-completion.plugins.bash"
	ln -s "../aliases/lib/a.aliases.bash" "$GAUDI_SHELL/components/enabled/150___a.aliases.bash"

	# Warnings are for interactive shells; a doctor run (log level) shows them too.
	# shellcheck disable=SC2016
	run env GAUDI_SHELL_LOG_LEVEL=2 "$BASH" --noprofile --norc -c 'source "$GAUDI_SHELL/gaudi_shell.sh" 2>&1 >/dev/null'
	assert_success
	assert_line --partial "150___gone.aliases.bash"
	# No such component: nothing to migrate to
	assert_line --partial "150___gone.aliases.bash' points to a missing file, skipped. Fix: gshell enable alias gone"
	# The component exists: the link is from another layout or directory
	assert_line --partial "365___alias-completion.plugins.bash' points to a missing file, skipped. Fix: gshell migrate"
	refute_output --partial "a.aliases.bash' points"
}

@test "gaudi-shell loader: links in the old layout are reported with 'gshell migrate' as the fix" {
	ln -s "../aliases/git.aliases.bash" "$GAUDI_SHELL/components/enabled/150___git.aliases.bash"
	ln -s "../completions/gaudi-shell.completions.bash" "$GAUDI_SHELL/components/enabled/350___gaudi-shell.completions.bash"

	# shellcheck disable=SC2016
	run env GAUDI_SHELL_LOG_LEVEL=2 "$BASH" --noprofile --norc -c 'source "$GAUDI_SHELL/gaudi_shell.sh" 2>&1 >/dev/null'
	assert_success
	assert_line --partial "150___git.aliases.bash' points to a missing file, skipped. Fix: gshell migrate"
	assert_line --partial "350___gaudi-shell.completions.bash' points to a missing file, skipped. Fix: gshell migrate"

	# The loader only reports: it never rewrites links at shell start
	run readlink "$GAUDI_SHELL/components/enabled/150___git.aliases.bash"
	assert_output "../aliases/git.aliases.bash"
}

@test "gaudi-shell loader: without the shared components every dangling link points to 'gshell migrate'" {
	# The component submodules were never fetched
	rm -rf "$GAUDI_SHELL/components/aliases/lib"
	ln -s "../aliases/a.aliases.bash" "$GAUDI_SHELL/components/enabled/150___a.aliases.bash"

	# shellcheck disable=SC2016
	run env GAUDI_SHELL_LOG_LEVEL=2 "$BASH" --noprofile --norc -c 'source "$GAUDI_SHELL/gaudi_shell.sh" 2>&1 >/dev/null'
	assert_success
	assert_line --partial "150___a.aliases.bash' points to a missing file, skipped. Fix: gshell migrate"
}

@test "gaudi-shell loader: a dangling link is skipped quietly in non-interactive shells" {
	ln -s "/nonexistent/gaudi-shell/components/aliases/gone.aliases.bash" "$GAUDI_SHELL/components/enabled/150___gone.aliases.bash"
	ln -s "../aliases/lib/a.aliases.bash" "$GAUDI_SHELL/components/enabled/150___a.aliases.bash"

	# shellcheck disable=SC2016
	run "$BASH" --noprofile --norc -c 'source "$GAUDI_SHELL/gaudi_shell.sh" 2>&1; alias test_alias'
	assert_success
	refute_output --partial "missing file"
	assert_line "alias test_alias='a'"
}
