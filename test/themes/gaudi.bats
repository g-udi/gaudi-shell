#!/usr/bin/env bats
# shellcheck shell=bats
# shellcheck disable=SC2030,SC2031

load "$GAUDI_TEST_DIRECTORY"/helper.bash
load "$GAUDI_TEST_DIRECTORY"/themes/scm_repos.bash

local_setup() {
	export TERM="xterm-256color"
	export GAUDI_SHELL_THEME="gaudi"
	export GAUDI_CWD_SHORTEN="false"
	PROMPT_SCRIPT="$BATS_TEST_TMPDIR/prompt.bash"
}

# Writes a script that loads gaudi-shell with the gaudi theme, runs the body
# given on stdin and is executed by the bash that is running the suite.
_write_prompt_script() {
	{
		# shellcheck disable=SC2016
		printf '%s\n' 'source "$GAUDI_SHELL/adapters/bash/init.bash"'
		cat
	} >"$PROMPT_SCRIPT"
}

# Creates a git work tree whose branch and directories are named like shell
# command substitutions, and moves into the innermost directory.
_enter_hostile_directory() {
	local work="$BATS_TEST_TMPDIR/work"

	mkdir -p "$work"
	cd "$work" || return 1
	git init -q .
	git commit -q --allow-empty -m init
	# shellcheck disable=SC2016
	git checkout -q -b '$(touch${IFS}pwned-branch)'
	# shellcheck disable=SC2016
	mkdir -p '$(touch pwned-dir)/`touch pwned-tick`'
	# shellcheck disable=SC2016
	cd '$(touch pwned-dir)/`touch pwned-tick`' || return 1
}

@test "gaudi theme: bash prompt: segment text is referenced from PS1, never pasted into it" {
	_enter_hostile_directory

	_write_prompt_script <<'SCRIPT'
GAUDI_PROMPT_LEFT=(cwd)
GAUDI_PROMPT_RIGHT=()
GAUDI_PROMPT_ASYNC=(scm)
gaudi::prompt
printf 'PS1=%s\n' "$PS1"
printf 'LINE=%s\n' "$_GAUDI_RENDERED_LINE"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	# shellcheck disable=SC2016
	assert_line 'PS1=\n${_GAUDI_RENDERED_LINE}\n\n\[${GAUDI_GREEN}\]>>\[${GAUDI_NC}\] '
	# The hostile names are shown as plain text
	# shellcheck disable=SC2016
	assert_output --partial '$(touch pwned-dir)/`touch pwned-tick`'
	# shellcheck disable=SC2016
	assert_output --partial '$(touch${IFS}pwned-branch)'
}

@test "gaudi theme: bash prompt: a directory or branch named like a command substitution is not executed" {
	if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
		skip "needs bash 4.4+ to expand a prompt string with \${PS1@P}"
	fi
	_enter_hostile_directory

	# The eval keeps bash 3.2 from choking on the @P operator while parsing.
	_write_prompt_script <<'SCRIPT'
GAUDI_PROMPT_LEFT=(cwd)
GAUDI_PROMPT_RIGHT=()
GAUDI_PROMPT_ASYNC=(scm)

gaudi::prompt
eval ': "${PS1@P}"'

shopt -u promptvars
gaudi::prompt
eval ': "${PS1@P}"'
case "$PS1" in *'${_GAUDI_RENDERED_LINE}'*) echo "reference left in PS1 with promptvars off" ;; esac

GAUDI_SPLIT_PROMPT=false
shopt -s promptvars
gaudi::prompt
eval ': "${PS1@P}"'
echo "rendered"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_line "rendered"
	refute_output --partial "reference left in PS1"

	run find "$BATS_TEST_TMPDIR/work" -name 'pwned*' -type f
	assert_output ""
}

@test "gaudi theme: bash prompt: backslashes in segment text stay literal when promptvars is off" {
	if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
		skip "needs bash 4.4+ to expand a prompt string with \${PS1@P}"
	fi
	mkdir -p "$BATS_TEST_TMPDIR/back\\wslash"
	cd "$BATS_TEST_TMPDIR/back\\wslash"

	_write_prompt_script <<'SCRIPT'
GAUDI_PROMPT_LEFT=(cwd)
GAUDI_PROMPT_RIGHT=()
GAUDI_PROMPT_ASYNC=()
GAUDI_SPLIT_PROMPT=false
shopt -u promptvars
gaudi::prompt
eval 'printf "%s\n" "${PS1@P}"'
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_output --partial 'back\wslash'
}

@test "gaudi theme: segment files are sourced once, not on every prompt" {
	cat >"$GAUDI_SHELL/components/themes/bash/gaudi/segments/probe.bash" <<'SEGMENT'
echo "sourced" >>"$GAUDI_PROBE_LOG"
gaudi_probe() {
	printf 'probe-output'
}
SEGMENT
	export GAUDI_PROBE_LOG="$BATS_TEST_TMPDIR/probe.log"

	_write_prompt_script <<'SCRIPT'
# Changing the configuration after start-up loads the new segment lazily
GAUDI_PROMPT_LEFT=(probe)
GAUDI_PROMPT_RIGHT=()
GAUDI_PROMPT_ASYNC=()
gaudi::prompt
gaudi::prompt
gaudi::prompt
printf 'LINE=%s\n' "$_GAUDI_RENDERED_LINE"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_output --partial "probe-output"

	run cat "$GAUDI_PROBE_LOG"
	assert_output "sourced"
}

@test "gaudi theme: the default segments are loaded when the theme starts" {
	_write_prompt_script <<'SCRIPT'
for segment in "${GAUDI_PROMPT_LEFT[@]}" "${GAUDI_PROMPT_RIGHT[@]}" "${GAUDI_PROMPT_ASYNC[@]}"; do
	type -t "gaudi_${segment}" >/dev/null || echo "not loaded: ${segment}"
done
echo "checked"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	refute_output --partial "not loaded"
	assert_line "checked"
}

# --- scm segment ---

@test "gaudi theme: scm: the git state of every sample repository is rendered" {
	export SCM_REPOS="$BATS_TEST_TMPDIR/repos"
	_make_scm_repos "$SCM_REPOS"

	_scm_render_script | _write_prompt_script

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	_assert_scm_states
	refute_output --partial "fatal:"
}

@test "gaudi theme: scm: a prompt in a git repository starts only a handful of git processes" {
	export SCM_REPOS="$BATS_TEST_TMPDIR/repos"
	_make_scm_repos "$SCM_REPOS"

	# A git that records every call before doing the real work
	local real_git shim="$BATS_TEST_TMPDIR/shim"
	real_git="$(command -v git)"
	mkdir -p "$shim"
	cat >"$shim/git" <<GIT
#!/usr/bin/env bash
echo "\$*" >>"$BATS_TEST_TMPDIR/git-calls"
exec "$real_git" "\$@"
GIT
	chmod +x "$shim/git"

	_write_prompt_script <<SCRIPT
GAUDI_PROMPT_LEFT=()
GAUDI_PROMPT_RIGHT=()
GAUDI_PROMPT_ASYNC=(scm)
cd "\$SCM_REPOS/mixed"
PATH="$shim:\$PATH"
gaudi::prompt
printf 'LINE=%s\n' "\$_GAUDI_RENDERED_LINE"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_output --partial "main +:2 !:1 ?:1"

	# status, rev-parse, stash count (and "git remote" when there is an upstream)
	run wc -l <"$BATS_TEST_TMPDIR/git-calls"
	[[ "$output" -le 4 ]]
	run grep -c '^status ' "$BATS_TEST_TMPDIR/git-calls"
	assert_output "1"
}

@test "gaudi theme: scm: settings made before the theme loads are kept" {
	export SCM_REPOS="$BATS_TEST_TMPDIR/repos"
	_make_scm_repos "$SCM_REPOS"

	{
		printf '%s\n' "GAUDI_SCM_THEME_PROMPT_DIRTY=' DIRTY'" "GAUDI_SCM_THEME_PROMPT_CLEAN=' CLEAN'" "GAUDI_SCM_THEME_DETACHED_PREFIX='at:'" "GAUDI_SCM_GIT_SHOW_DETAILS=false"
		# shellcheck disable=SC2016
		printf '%s\n' 'source "$GAUDI_SHELL/adapters/bash/init.bash"'
		cat <<'SCRIPT'
for repo in clean dirty detached; do
	cd "$SCM_REPOS/$repo" || continue
	scm_prompt_vars
	printf '%s=%s%s\n' "$repo" "$GAUDI_SCM_BRANCH" "$GAUDI_SCM_STATE"
done
type -t scm_prompt_info scm_char git_prompt_minimal_info _git-upstream-branch-gone gaudi::displaytime || echo "dead code is gone"
SCRIPT
	} >"$PROMPT_SCRIPT"

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_line "clean=main CLEAN"
	assert_line "dirty=main DIRTY"
	assert_line --regexp '^detached=at:[^ ]+ CLEAN$'
	assert_line "dead code is gone"
}

@test "gaudi theme: scm: hide-status reads the gaudi-shell key and still honours the old one" {
	export SCM_REPOS="$BATS_TEST_TMPDIR/repos"
	_make_scm_repos "$SCM_REPOS"
	git -C "$SCM_REPOS/dirty" config gaudi-shell.hide-status 1
	git -C "$SCM_REPOS/staged" config gaudi-bash.hide-status 1

	_write_prompt_script <<'SCRIPT'
for repo in clean dirty staged; do
	cd "$SCM_REPOS/$repo" || continue
	printf '%s=[%s]\n' "$repo" "$(git_prompt_info)"
done
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_line "clean=[main]"
	assert_line "dirty=[]"
	assert_line "staged=[]"
}

# --- cwd segment ---

@test "gaudi theme: cwd: long paths are shortened from the middle, never the last name" {
	_write_prompt_script <<'SCRIPT'
HOME=/Users/tester
for dir in / /Users/tester /Users/tester/x /Users/testerx/y \
	/Users/tester/aaaaaaaaaaaa/bbbbbbbbbbbb/cc/dddddddddddd \
	/Users/tester/Projects/some-client/website/src/components/buttons \
	/usr/local/share/very-long-directory-name/another-long-one/leaf \
	"/Users/tester/with space/and more spaces here/x y z/leafleafleaf" \
	/a-very-long-directory-name-that-cannot-be-shortened-at-all; do
	printf '[%s]\n' "$(gaudi::shorten_path "$dir")"
done
printf 'full=[%s]\n' "$(gaudi::tilde_path /Users/tester/Projects/x)"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_line "[⚠ ROOT]"
	assert_line "[~]"
	assert_line "[~/x]"
	# Only a whole leading directory is the home directory
	assert_line "[/Users/testerx/y]"
	assert_line "[~/a/bbbbbbbbbbbb/cc/dddddddddddd]"
	assert_line "[~/P/s/website/src/c/buttons]"
	assert_line "[/usr/local/share/v/a/leaf]"
	assert_line "[~/with space/a/x y z/leafleafleaf]"
	assert_line "[/a-very-long-directory-name-that-cannot-be-shortened-at-all]"
	assert_line "full=[~/Projects/x]"
	# No stray slash, no blind cut through the middle of a name
	refute_output --regexp '/\]'
	refute_output --partial "~cc"
}

# --- docker, has_files, continuation ---

@test "gaudi theme: docker: COMPOSE_FILE with several files is split without errors" {
	local fakebin="$BATS_TEST_TMPDIR/fakebin" work="$BATS_TEST_TMPDIR/compose"
	mkdir -p "$fakebin" "$work"
	printf '%s\n' '#!/usr/bin/env bash' 'echo "27.1.0-rc1"' >"$fakebin/docker"
	chmod +x "$fakebin/docker"
	touch "$work/one.yml" "$work/two.yml"
	cd "$work"

	_write_prompt_script <<SCRIPT
PATH="$fakebin:\$PATH"
gaudi::load_segment docker
COMPOSE_FILE="one.yml:two.yml"
printf 'both=[%s]\n' "\$(gaudi_docker)"
COMPOSE_FILE="one.yml:missing.yml"
printf 'missing=[%s]\n' "\$(gaudi_docker)"
COMPOSE_FILE="one.yml;two.yml" COMPOSE_PATH_SEPARATOR=";"
printf 'separator=[%s]\n' "\$(gaudi_docker)"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	refute_output --partial "bad substitution"
	assert_line --partial "both=["
	assert_line --partial "27.1.0"
	assert_line "missing=[]"
	assert_line --regexp '^separator=\[.*27\.1\.0'
}

@test "gaudi theme: has_files finds entries by extension without starting a process" {
	local work="$BATS_TEST_TMPDIR/files"
	mkdir -p "$work/empty" "$work/hidden" "$work/some"
	touch "$work/hidden/.secret.js" "$work/some/app.js" "$work/some/with space.rb"
	ln -s /nonexistent "$work/some/dangling.py"

	_write_prompt_script <<SCRIPT
cd "$work/empty" && { gaudi::has_files js || echo "empty: no"; }
cd "$work/hidden" && { gaudi::has_files js || echo "hidden: no"; }
cd "$work/some" && gaudi::has_files js && echo "js: yes"
gaudi::has_files go rb && echo "second extension: yes"
gaudi::has_files py && echo "dangling link: yes"
gaudi::has_files go rs || echo "others: no"
grep -l 'find \.' "\$GAUDI_ROOT"/segments/*.bash || echo "no segment calls find"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_line "empty: no"
	assert_line "hidden: no"
	assert_line "js: yes"
	assert_line "second extension: yes"
	assert_line "dangling link: yes"
	assert_line "others: no"
	assert_line "no segment calls find"
}

@test "gaudi theme: the continuation prompt and the char segment no longer share variables" {
	_write_prompt_script <<'SCRIPT'
gaudi::load_segment char
RETVAL=0
printf 'char=[%s]\n' "$(gaudi_char)"
printf 'symbols=[%s][%s]\n' "$GAUDI_CHAR_SYMBOL" "$GAUDI_CONTINUATION_SYMBOL"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_line --partial ">>"
	# The continuation glyph is kept as its escape (backslash, then uf6d7)
	assert_line --regexp '^symbols=\[>>\]\[.uf6d7\]$'
}

@test "gaudi theme: the continuation prompt still follows the old GAUDI_CHAR_* names when they are set" {
	{
		printf '%s\n' "GAUDI_CHAR_SYMBOL='old-name'"
		# shellcheck disable=SC2016
		printf '%s\n' 'source "$GAUDI_SHELL/adapters/bash/init.bash"' 'printf "continuation=[%s]\n" "$GAUDI_CONTINUATION_SYMBOL"'
	} >"$PROMPT_SCRIPT"

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_line "continuation=[old-name]"
}

@test "gaudi theme: colours are literal escape sequences, set without running tput" {
	local fakebin="$BATS_TEST_TMPDIR/fakebin"
	mkdir -p "$fakebin"
	printf '%s\n' '#!/usr/bin/env bash' "echo \"\$*\" >>\"$BATS_TEST_TMPDIR/tput-calls\"" 'exit 1' >"$fakebin/tput"
	chmod +x "$fakebin/tput"
	: >"$BATS_TEST_TMPDIR/tput-calls"

	{
		printf '%s\n' "PATH=\"$fakebin:\$PATH\""
		# shellcheck disable=SC2016
		printf '%s\n' 'source "$GAUDI_SHELL/adapters/bash/init.bash"'
		# shellcheck disable=SC2016
		printf '%s\n' 'printf "%s" "$GAUDI_RED$BACKGROUND_GAUDI_ORANGE$GAUDI_NC" | od -An -c | tr -d " \n"; echo'
	} >"$PROMPT_SCRIPT"

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_line '033[31m033[48;5;202m033(B033[m'

	# Only the core asks tput once, for the number of colours
	run cat "$BATS_TEST_TMPDIR/tput-calls"
	assert_output "colors"
}

@test "gaudi theme: the reset of the theme has its own name and the framework's NC keeps its value" {
	_write_prompt_script <<'SCRIPT'
printf '%s' "nc=[$NC] theme=[$GAUDI_NC]" | od -An -c | tr -d " \n"
echo
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	# NC is what lib/colors.bash gave it: empty, or the plain reset
	assert_line --regexp '^nc=\[(033\[0m)?\]theme=\[033\(B033\[m\]$'
}

@test "gaudi theme: node: a lazy-load stub named nvm or node is never called" {
	local fakebin="$BATS_TEST_TMPDIR/fakebin" project="$BATS_TEST_TMPDIR/project"
	mkdir -p "$fakebin" "$project"
	printf '%s\n' '#!/usr/bin/env bash' 'echo "v20.1.0"' >"$fakebin/node"
	chmod +x "$fakebin/node"
	echo '{}' >"$project/package.json"
	export STUB_LOG="$BATS_TEST_TMPDIR/stub-calls" FAKEBIN="$fakebin" PROJECT="$project"

	_write_prompt_script <<'SCRIPT'
# What the nvm plugin defines until nvm is first used
nvm() { echo "nvm $*" >>"$STUB_LOG"; }
node() { echo "node $*" >>"$STUB_LOG"; }
PATH="$FAKEBIN:$PATH"
cd "$PROJECT" || exit 1
gaudi::load_segment node
printf '%s\n' "node=[$(gaudi_node)]"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_line --partial "v20.1.0"
	assert_file_not_exist "$STUB_LOG"
}

@test "gaudi theme: duration: COMMAND_DURATION_MIN_SECONDS is the default of GAUDI_DURATION_MIN_SECONDS" {
	{
		# shellcheck disable=SC2016
		printf '%s\n' 'COMMAND_DURATION_MIN_SECONDS=5' \
			'source "$GAUDI_SHELL/adapters/bash/init.bash"' \
			'gaudi::load_segment duration' \
			'echo "min=$GAUDI_DURATION_MIN_SECONDS"'
	} >"$PROMPT_SCRIPT"

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_line "min=5"
}

@test "gaudi theme: battery: nothing is printed on a machine without a battery" {
	local fakebin="$BATS_TEST_TMPDIR/fakebin"
	mkdir -p "$fakebin"
	# No "InternalBattery" line (macOS), no battery device (Linux)
	printf '%s\n' '#!/usr/bin/env bash' "echo \"Now drawing from 'AC Power'\"" >"$fakebin/pmset"
	printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$fakebin/upower"
	chmod +x "$fakebin/pmset" "$fakebin/upower"
	export FAKEBIN="$fakebin"

	_write_prompt_script <<'SCRIPT'
PATH="$FAKEBIN:$PATH"
gaudi::load_segment battery
printf '%s\n' "battery=[$(gaudi_battery)]"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_line "battery=[]"
}

@test "gaudi theme: the bash adapter works out an absolute install directory by itself" {
	cd "$GAUDI_SHELL/adapters/bash"
	# shellcheck disable=SC2016
	run env -u GAUDI_SHELL -u GAUDI_SHELL_THEME "$BASH" --noprofile --norc -c 'source ./init.bash; cd /; echo "dir=$GAUDI_SHELL"'
	assert_success
	assert_line "dir=$(cd "$GAUDI_SHELL" && pwd)"
}
