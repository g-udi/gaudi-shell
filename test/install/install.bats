#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	if [[ "$OSTYPE" == darwin* ]]; then
		export GAUDI_SHELL_PROFILE=".bash_profile"
	else
		export GAUDI_SHELL_PROFILE=".bashrc"
	fi
	export SHELL="/bin/bash"
}

@test "gaudi-shell install: verify that the install script exists" {

	assert_file_exist "$GAUDI_SHELL/install.sh"
}

@test "gaudi-shell install: verify that the setup script exists" {

	assert_file_exist "$GAUDI_SHELL/setup.sh"
}

@test "gaudi-shell install: run the install script silently by skipping prompts" {

	# Without this the relative path below would be the setup script of the
	# repository under test, and it would enable components in that checkout.
	cd "$GAUDI_SHELL"

	run ./setup.sh --silent --shell bash
	[[ -z $output ]]
	assert_file_exist "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
}

@test "gaudi-shell install: run the install script silently and check that config file exists" {

	cd "$GAUDI_SHELL"

	./setup.sh --silent --shell bash
	assert_file_exist "$HOME/$GAUDI_SHELL_PROFILE"
}

@test "gaudi-shell install: run the install script silently and enable sane defaults" {

	cd "$GAUDI_SHELL"

	./setup.sh --silent --shell bash

	assert_file_exist "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/325___system.completions.bash"
}

@test "gaudi-shell install: run the install script silently and don't modify configs" {
	rm -rf "${HOME:?}/${GAUDI_SHELL_PROFILE:?}"

	cd "$GAUDI_SHELL"
	./setup.sh --silent --shell bash --no-modify-config

	assert_file_not_exist "$HOME/${GAUDI_SHELL_PROFILE}"
}

@test "gaudi-shell install: verify that a backup file is created" {

	cd "$GAUDI_SHELL" || exit

	# HOME is shared by the tests of this file: start without older backups
	rm -f "$HOME/$GAUDI_SHELL_PROFILE.bak" "$HOME/$GAUDI_SHELL_PROFILE.bak".*
	touch "$HOME/$GAUDI_SHELL_PROFILE"
	echo "test file content" >"$HOME/$GAUDI_SHELL_PROFILE"
	cp "$HOME/$GAUDI_SHELL_PROFILE" "$BATS_TEST_TMPDIR/original"

	./setup.sh --silent --shell bash

	assert_file_exist "$HOME/$GAUDI_SHELL_PROFILE"
	assert_file_exist "$HOME/$GAUDI_SHELL_PROFILE.bak"

	run cmp "$BATS_TEST_TMPDIR/original" "$HOME/$GAUDI_SHELL_PROFILE.bak"
	assert_success
}

@test "gaudi-shell install: setup auto-detects zsh from SHELL" {

	cd "$GAUDI_SHELL"

	SHELL="/bin/zsh" ./setup.sh --silent

	assert_file_exist "$HOME/.zshrc"
	run grep -F "source \"\$GAUDI_SHELL/adapters/zsh/init.zsh\"" "$HOME/.zshrc"
	assert_success
	run grep -F '#!/usr/bin/env bash' "$HOME/.zshrc"
	assert_failure
}

@test "gaudi-shell install: sourced setup resolves the setup script directory" {

	local wrapper="$BATS_TEST_TMPDIR/source-setup.sh"

	# A profile left by an earlier test already loads gaudi-shell and would be
	# kept as it is; this test is about a first installation.
	rm -f "$HOME/$GAUDI_SHELL_PROFILE"

	cat >"$wrapper" <<WRAPPER
#!/usr/bin/env bash
source "$GAUDI_SHELL/setup.sh" --silent --shell bash
WRAPPER
	chmod +x "$wrapper"

	run "$wrapper"
	assert_success

	assert_file_exist "$HOME/$GAUDI_SHELL_PROFILE"
	run grep -F "export GAUDI_SHELL=\"$GAUDI_SHELL\"" "$HOME/$GAUDI_SHELL_PROFILE"
	assert_success
}

@test "gaudi-shell install: installer runs cloned setup for detected shell" {

	local fakebin="$BATS_TEST_TMPDIR/fakebin"
	local install_home="$BATS_TEST_TMPDIR/install-home"

	mkdir -p "$fakebin" "$install_home"
	cat >"$fakebin/git" <<'GIT'
#!/usr/bin/env bash
if [[ "$1" == "clone" ]]; then
	destination=""
	for arg in "$@"; do
		destination="$arg"
	done

	mkdir -p "$destination"
	tar -C "$GAUDI_SHELL_ORIGIN" \
		--exclude='.git' \
		--exclude='bin' \
		--exclude='./profiles' \
		--exclude='./components/enabled' \
		--exclude='./components/custom' \
		--exclude='./tmp' \
		-cf - . | tar -C "$destination" -xf -
	exit 0
fi
# The component submodules: the copy above already holds their content
[[ "$3 $4 $5" == "submodule update --init" ]] && exit 0

exit 1
GIT
	chmod +x "$fakebin/git"

	run env PATH="$fakebin:$PATH" HOME="$install_home" SHELL="/bin/zsh" "$GAUDI_SHELL_ORIGIN/install.sh" --silent
	assert_success

	assert_file_exist "$install_home/.gaudi-shell/setup.sh"
	assert_file_exist "$install_home/.zshrc"
	run grep -F "export GAUDI_SHELL=\"$install_home/.gaudi-shell\"" "$install_home/.zshrc"
	assert_success
	run grep -F "source \"\$GAUDI_SHELL/adapters/zsh/init.zsh\"" "$install_home/.zshrc"
	assert_success
}

@test "gaudi-shell install: setup stops, before touching the config, when the component submodules are empty" {

	local home="$BATS_TEST_TMPDIR/home"
	mkdir -p "$home"
	# What a clone without submodules leaves behind: empty folders
	rm -rf "$GAUDI_SHELL/components/aliases" "$GAUDI_SHELL/components/completions" "$GAUDI_SHELL/components/plugins"
	mkdir "$GAUDI_SHELL/components/aliases" "$GAUDI_SHELL/components/completions" "$GAUDI_SHELL/components/plugins"

	cd "$GAUDI_SHELL"
	run env HOME="$home" ./setup.sh --shell bash
	assert_failure
	assert_output --partial "shared components are missing"
	# The exact command that fixes it
	assert_line "  git -C \"$GAUDI_SHELL\" submodule update --init components/aliases components/completions components/plugins"
	assert_file_not_exist "$home/$GAUDI_SHELL_PROFILE"
	assert_file_not_exist "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"

	# --silent keeps quiet about progress, not about this
	run env HOME="$home" ./setup.sh --silent --shell bash
	assert_failure
	assert_output --partial "submodule update --init components/aliases components/completions components/plugins"
	assert_file_not_exist "$home/$GAUDI_SHELL_PROFILE"
}

@test "gaudi-shell install: setup stops when only one component submodule is empty" {

	local home="$BATS_TEST_TMPDIR/home"
	mkdir -p "$home"
	rm -rf "$GAUDI_SHELL/components/plugins"
	mkdir "$GAUDI_SHELL/components/plugins"

	cd "$GAUDI_SHELL"
	run env HOME="$home" ./setup.sh --silent --shell bash
	assert_failure
	assert_output --partial "shared components are missing"
}

@test "gaudi-shell install: setup migrates enabled links left by the old layout" {

	local home="$BATS_TEST_TMPDIR/home"
	mkdir -p "$home"
	ln -s "../aliases/git.aliases.bash" "$GAUDI_SHELL/components/enabled/150___git.aliases.bash"
	ln -s "../plugins/alias-completion.plugins.bash" "$GAUDI_SHELL/components/enabled/365___alias-completion.plugins.bash"

	cd "$GAUDI_SHELL"
	run env HOME="$home" ./setup.sh --shell bash
	assert_success
	assert_line "migrated 150___git.aliases.bash -> ../aliases/lib/git.aliases.bash"
	assert_line "migrated 365___alias-completion.plugins.bash -> ../plugins/lib/alias-completion.plugins.bash"

	run readlink "$GAUDI_SHELL/components/enabled/150___git.aliases.bash"
	assert_output "../aliases/lib/git.aliases.bash"
	assert_file_exist "$GAUDI_SHELL/components/enabled/365___alias-completion.plugins.bash"
}

@test "gaudi-shell install: silent setup appends to an existing config and keeps its content" {

	local home="$BATS_TEST_TMPDIR/home"
	mkdir -p "$home"
	echo "export KEEP_ME=1" >"$home/$GAUDI_SHELL_PROFILE"

	cd "$GAUDI_SHELL"
	run env HOME="$home" ./setup.sh --silent --shell bash
	assert_success

	run cat "$home/$GAUDI_SHELL_PROFILE"
	assert_line --index 0 "export KEEP_ME=1"
	assert_line "export GAUDI_SHELL=\"$GAUDI_SHELL\""
	assert_line "source \"\$GAUDI_SHELL/adapters/bash/init.bash\""

	run cat "$home/$GAUDI_SHELL_PROFILE.bak"
	assert_output "export KEEP_ME=1"
}

@test "gaudi-shell install: running setup twice changes nothing the second time" {

	local home="$BATS_TEST_TMPDIR/home"
	local first_run
	mkdir -p "$home"
	echo "export KEEP_ME=1" >"$home/$GAUDI_SHELL_PROFILE"

	cd "$GAUDI_SHELL"
	env HOME="$home" ./setup.sh --silent --shell bash
	first_run="$(cat "$home/$GAUDI_SHELL_PROFILE")"

	run env HOME="$home" ./setup.sh --silent --shell bash
	assert_success

	# Not appended again
	assert_equal "$(cat "$home/$GAUDI_SHELL_PROFILE")" "$first_run"
	run grep -c "adapters/bash/init.bash" "$home/$GAUDI_SHELL_PROFILE"
	assert_output "1"

	# The backup still holds the original file and no other backup was made
	run cat "$home/$GAUDI_SHELL_PROFILE.bak"
	assert_output "export KEEP_ME=1"
	run find "$home" -name "$GAUDI_SHELL_PROFILE.bak.*"
	assert_output ""
}

@test "gaudi-shell install: an existing backup is never overwritten" {

	local home="$BATS_TEST_TMPDIR/home"
	local backups
	mkdir -p "$home"
	echo "current config" >"$home/$GAUDI_SHELL_PROFILE"
	echo "precious original" >"$home/$GAUDI_SHELL_PROFILE.bak"

	cd "$GAUDI_SHELL"
	run env HOME="$home" ./setup.sh --silent --shell bash
	assert_success

	run cat "$home/$GAUDI_SHELL_PROFILE.bak"
	assert_output "precious original"

	# The file as it was before this run went to a timestamped backup
	backups="$(find "$home" -name "$GAUDI_SHELL_PROFILE.bak.*")"
	assert [ -n "$backups" ]
	run cat "$backups"
	assert_output "current config"
}

@test "gaudi-shell install: answering no replaces the config but keeps a backup" {

	local home="$BATS_TEST_TMPDIR/home"
	mkdir -p "$home"
	echo "export KEEP_ME=1" >"$home/$GAUDI_SHELL_PROFILE"

	cd "$GAUDI_SHELL"
	run env HOME="$home" ./setup.sh --shell bash <<<"n"
	assert_success

	run grep -c "KEEP_ME" "$home/$GAUDI_SHELL_PROFILE"
	assert_output "0"
	run grep -c "adapters/bash/init.bash" "$home/$GAUDI_SHELL_PROFILE"
	assert_output "1"
	run cat "$home/$GAUDI_SHELL_PROFILE.bak"
	assert_output "export KEEP_ME=1"
}

@test "gaudi-shell install: setup does not loop or replace the config when the question cannot be answered" {

	local home="$BATS_TEST_TMPDIR/home"
	mkdir -p "$home"
	echo "export KEEP_ME=1" >"$home/$GAUDI_SHELL_PROFILE"

	cd "$GAUDI_SHELL"
	run env HOME="$home" ./setup.sh --shell bash </dev/null
	assert_success

	run cat "$home/$GAUDI_SHELL_PROFILE"
	assert_line --index 0 "export KEEP_ME=1"
	assert_line "source \"\$GAUDI_SHELL/adapters/bash/init.bash\""
}

# --- running the installer again over an existing install ---

# A home directory with an install already in place, and a fake git that only
# records how it was called.
_existing_install() {
	INSTALL_HOME="$BATS_TEST_TMPDIR/install-home"
	FAKEBIN="$BATS_TEST_TMPDIR/fakebin"
	GIT_CALLS="$BATS_TEST_TMPDIR/git-calls"

	mkdir -p "$INSTALL_HOME/.gaudi-shell/lib/helpers" "$FAKEBIN"
	echo "existing" >"$INSTALL_HOME/.gaudi-shell/marker"
	# The installer takes its component helpers from the install itself
	cp "$GAUDI_SHELL_ORIGIN/lib/helpers/components.bash" "$INSTALL_HOME/.gaudi-shell/lib/helpers/"
	: >"$GIT_CALLS"
	cat >"$FAKEBIN/git" <<GIT
#!/usr/bin/env bash
echo "\$*" >>"$GIT_CALLS"
case "\$*" in
# An install "gshell update" left on a tag has no current branch
*symbolic-ref*) [[ -z "\$FAKE_GIT_DETACHED" ]] || exit 1 ;;
*rev-list*) echo "abc123" ;;
*describe*) echo "v9.9.9" ;;
esac
if [[ "\$1" == "clone" ]]; then
	# Stands in for the clone: an install with a setup script that only reports
	for destination in "\$@"; do :; done
	mkdir -p "\$destination/lib/helpers"
	cp "$GAUDI_SHELL_ORIGIN/lib/helpers/components.bash" "\$destination/lib/helpers/"
	printf '%s\n' '#!/usr/bin/env bash' 'echo "fresh setup ran"' >"\$destination/setup.sh"
	chmod +x "\$destination/setup.sh"
fi
exit 0
GIT
	chmod +x "$FAKEBIN/git"
}

_run_installer() {
	run env PATH="$FAKEBIN:$PATH" HOME="$INSTALL_HOME" "$GAUDI_SHELL_ORIGIN/install.sh" --silent
}

@test "gaudi-shell install: over an existing install, no answer stops without pulling or deleting" {
	_existing_install

	_run_installer </dev/null
	assert_failure
	assert_output --partial "nothing was changed"

	run cat "$GIT_CALLS"
	assert_output ""
	assert_file_exist "$INSTALL_HOME/.gaudi-shell/marker"
}

@test "gaudi-shell install: over an existing install, an answer other than y or n aborts" {
	_existing_install

	_run_installer <<<"maybe"
	assert_failure
	assert_output --partial "Please answer y or n"
	# Asked once only
	assert_equal "$(grep -o "fresh installation" <<<"$output" | wc -l | tr -d ' ')" "1"

	run cat "$GIT_CALLS"
	assert_output ""
	assert_file_exist "$INSTALL_HOME/.gaudi-shell/marker"
}

@test "gaudi-shell install: over an existing install, n pulls exactly once" {
	_existing_install

	_run_installer <<<"n"
	assert_success

	# ... and then brings the shared components (only those three submodules)
	# to the commits the pulled version pins
	run cat "$GIT_CALLS"
	assert_line --index 0 "-C $INSTALL_HOME/.gaudi-shell symbolic-ref -q HEAD"
	assert_line --index 1 "-C $INSTALL_HOME/.gaudi-shell pull"
	assert_line --index 2 "-C $INSTALL_HOME/.gaudi-shell submodule update --init components/aliases components/completions components/plugins"
	assert_equal "${#lines[@]}" "3"
	assert_file_exist "$INSTALL_HOME/.gaudi-shell/marker"
}

@test "gaudi-shell install: over an existing install left on a tag by 'gshell update', n checks out the latest tag instead of pulling" {
	_existing_install

	FAKE_GIT_DETACHED=1 _run_installer <<<"n"
	assert_success

	run cat "$GIT_CALLS"
	refute_line --partial " pull"
	assert_line "-C $INSTALL_HOME/.gaudi-shell fetch --tags origin"
	assert_line "-C $INSTALL_HOME/.gaudi-shell describe --tags abc123"
	assert_line "-C $INSTALL_HOME/.gaudi-shell checkout v9.9.9"
	assert_line "-C $INSTALL_HOME/.gaudi-shell submodule update --init components/aliases components/completions components/plugins"
}

@test "gaudi-shell install: over an existing install, y removes it and clones again" {
	_existing_install
	# The user's own files
	mkdir -p "$INSTALL_HOME/.gaudi-shell/profiles" "$INSTALL_HOME/.gaudi-shell/components/custom"
	echo "alias general" >"$INSTALL_HOME/.gaudi-shell/profiles/work.gaudi-shell"
	echo "alias mine='true'" >"$INSTALL_HOME/.gaudi-shell/components/custom/mine.bash"

	_run_installer <<<"y"
	assert_success
	assert_output --partial "fresh setup ran"

	run cat "$GIT_CALLS"
	assert_line --partial "clone --depth=1"
	# Only the component submodules are fetched, not the test tools in bin/
	refute_line --partial "--recurse-submodules"
	assert_line "-C $INSTALL_HOME/.gaudi-shell submodule update --init --depth=1 components/aliases components/completions components/plugins"
	refute_line --partial "pull"
	assert_file_not_exist "$INSTALL_HOME/.gaudi-shell/marker"

	# Profiles and custom scripts were moved into the fresh install
	run cat "$INSTALL_HOME/.gaudi-shell/profiles/work.gaudi-shell"
	assert_output "alias general"
	assert_file_exist "$INSTALL_HOME/.gaudi-shell/components/custom/mine.bash"
}
