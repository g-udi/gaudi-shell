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

	run ./setup.sh --silent --shell bash
	[[ -z $output ]]
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

	local md5_orig
	local md5_bak

	cd "$GAUDI_SHELL" || exit

	touch "$HOME/$GAUDI_SHELL_PROFILE"
	echo "test file content" >"$HOME/$GAUDI_SHELL_PROFILE"
	md5_orig=$(md5sum "$HOME/$GAUDI_SHELL_PROFILE" | awk '{print $1}')

	./setup.sh --silent --shell bash

	assert_file_exist "$HOME/$GAUDI_SHELL_PROFILE"
	assert_file_exist "$HOME/$GAUDI_SHELL_PROFILE.bak"

	md5_bak=$(md5sum "$HOME/$GAUDI_SHELL_PROFILE.bak" | awk '{print $1}')

	assert_equal "$md5_orig" "$md5_bak"
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
		-cf - . | tar -C "$destination" -xf -
	exit 0
fi

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
