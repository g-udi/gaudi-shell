#!/usr/bin/env bats
# shellcheck shell=bats

# The enabled links of an install made before the shared components became
# submodules point at components/<type>/<file>; the files are now at
# components/<type>/lib/<file> (shared) or components/host/<file> (own).

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs log colors gaudi-shell
	ENABLED="$GAUDI_SHELL/components/enabled"
}

@test "gaudi-shell helpers: migrate: a link in the old relative form is pointed at the new location" {
	ln -s "../aliases/git.aliases.bash" "$ENABLED/150___git.aliases.bash"
	ln -s "../plugins/alias-completion.plugins.bash" "$ENABLED/365___alias-completion.plugins.bash"

	run _gaudi-shell-migrate-enabled-links
	assert_success
	# One line per migrated link
	assert_equal "${#lines[@]}" "2"
	assert_line "migrated 150___git.aliases.bash -> ../aliases/lib/git.aliases.bash"
	assert_line "migrated 365___alias-completion.plugins.bash -> ../plugins/lib/alias-completion.plugins.bash"

	run readlink "$ENABLED/150___git.aliases.bash"
	assert_output "../aliases/lib/git.aliases.bash"
	# The priority prefix is kept, not worked out again
	run readlink "$ENABLED/365___alias-completion.plugins.bash"
	assert_output "../plugins/lib/alias-completion.plugins.bash"
	assert_file_exist "$ENABLED/150___git.aliases.bash"
	assert_file_exist "$ENABLED/365___alias-completion.plugins.bash"
}

@test "gaudi-shell helpers: migrate: the framework's own files move to components/host" {
	ln -s "../completions/gaudi-shell.completions.bash" "$ENABLED/350___gaudi-shell.completions.bash"
	ln -s "../aliases/gaudi-shell.aliases.bash" "$ENABLED/150___gaudi-shell.aliases.bash"

	run _gaudi-shell-migrate-enabled-links
	assert_success
	assert_line "migrated 350___gaudi-shell.completions.bash -> ../host/gaudi-shell.completions.bash"
	assert_line "migrated 150___gaudi-shell.aliases.bash -> ../host/gaudi-shell.aliases.bash"
	assert_file_exist "$ENABLED/350___gaudi-shell.completions.bash"
}

@test "gaudi-shell helpers: migrate: a link with an old absolute target is pointed at the new location" {
	ln -s "$GAUDI_SHELL/components/plugins/base.plugins.bash" "$ENABLED/250___base.plugins.bash"
	ln -s "/somewhere/else/.gaudi-shell/components/completions/system.completions.bash" "$ENABLED/325___system.completions.bash"

	run _gaudi-shell-migrate-enabled-links
	assert_success
	assert_line "migrated 250___base.plugins.bash -> ../plugins/lib/base.plugins.bash"
	assert_line "migrated 325___system.completions.bash -> ../completions/lib/system.completions.bash"

	run readlink "$ENABLED/250___base.plugins.bash"
	assert_output "../plugins/lib/base.plugins.bash"
	assert_file_exist "$ENABLED/325___system.completions.bash"
}

@test "gaudi-shell helpers: migrate: links that already work are left alone, so a second run does nothing" {
	ln -s "../aliases/git.aliases.bash" "$ENABLED/150___git.aliases.bash"
	_gaudi-shell-enable plugin base >/dev/null
	# A working absolute link is not rewritten either
	ln -s "$GAUDI_SHELL/components/aliases/lib/general.aliases.bash" "$ENABLED/150___general.aliases.bash"

	run _gaudi-shell-migrate-enabled-links
	assert_output "migrated 150___git.aliases.bash -> ../aliases/lib/git.aliases.bash"

	run _gaudi-shell-migrate-enabled-links
	assert_success
	assert_output ""
	run readlink "$ENABLED/250___base.plugins.bash"
	assert_output "../plugins/lib/base.plugins.bash"
	run readlink "$ENABLED/150___general.aliases.bash"
	assert_output "$GAUDI_SHELL/components/aliases/lib/general.aliases.bash"
}

@test "gaudi-shell helpers: migrate: a link to a component that no longer exists is left as it is" {
	ln -s "../aliases/gone.aliases.bash" "$ENABLED/150___gone.aliases.bash"
	# Another framework's own file is not a component here
	ln -s "../aliases/gaudi-bash.aliases.bash" "$ENABLED/150___gaudi-bash.aliases.bash"

	run _gaudi-shell-migrate-enabled-links
	assert_success
	assert_output ""
	run readlink "$ENABLED/150___gone.aliases.bash"
	assert_output "../aliases/gone.aliases.bash"
	run readlink "$ENABLED/150___gaudi-bash.aliases.bash"
	assert_output "../aliases/gaudi-bash.aliases.bash"
}

@test "gaudi-shell helpers: migrate: without an enabled folder there is nothing to do" {
	rm -rf "$ENABLED"
	run _gaudi-shell-migrate-enabled-links
	assert_success
	assert_output ""
}

@test "gaudi-shell helpers: migrate: migrated components show as enabled" {
	# The cached listing was written while the link was dangling
	ln -s "../aliases/git.aliases.bash" "$ENABLED/150___git.aliases.bash"
	run _gaudi-shell-describe aliases
	assert_line --regexp "^git +.*◯"

	_gaudi-shell-migrate-enabled-links >/dev/null

	run _gaudi-shell-describe aliases
	assert_line --regexp "^git +.*◉"
}

@test "gaudi-shell helpers: migrate: 'gshell migrate' repairs the links and says what to do next" {
	ln -s "../aliases/git.aliases.bash" "$ENABLED/150___git.aliases.bash"

	run gshell migrate
	assert_success
	assert_line "migrated 150___git.aliases.bash -> ../aliases/lib/git.aliases.bash"
	assert_line --partial "gshell reload"

	run gshell migrate
	assert_success
	assert_output "Nothing to migrate."
}

@test "gaudi-shell helpers: migrate: 'gshell migrate' fetches the shared components when they are missing" {
	rm -rf "$GAUDI_SHELL/components/aliases/lib"
	local fakebin="$BATS_TEST_TMPDIR/fakebin"
	mkdir -p "$fakebin"
	# Stands in for git: records the call, the network is never used
	cat >"$fakebin/git" <<GIT
#!/usr/bin/env bash
echo "\$*" >>"$BATS_TEST_TMPDIR/git-calls"
exit 0
GIT
	chmod +x "$fakebin/git"

	PATH="$fakebin:$PATH" run gshell migrate
	assert_success
	run cat "$BATS_TEST_TMPDIR/git-calls"
	assert_output "-C $GAUDI_SHELL submodule update --init components/aliases components/completions components/plugins"
}

@test "gaudi-shell helpers: migrate: 'gshell migrate' gives the command to run when the components cannot be fetched" {
	rm -rf "$GAUDI_SHELL/components/plugins/lib"
	local fakebin="$BATS_TEST_TMPDIR/fakebin"
	mkdir -p "$fakebin"
	printf '%s\n' '#!/usr/bin/env bash' 'exit 1' >"$fakebin/git"
	chmod +x "$fakebin/git"

	PATH="$fakebin:$PATH" run gshell migrate
	assert_failure
	assert_output --partial "git -C \"$GAUDI_SHELL\" submodule update --init components/aliases components/completions components/plugins"
}
