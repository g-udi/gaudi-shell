#!/usr/bin/env bats
# shellcheck shell=bats
# shellcheck disable=SC2030,SC2031

# Smoke tests for the zsh adapter: every test runs a small script in `zsh -f`
# (no user configuration) against the test copy of gaudi-shell.

load "$GAUDI_TEST_DIRECTORY"/helper.bash
load "$GAUDI_TEST_DIRECTORY"/themes/scm_repos.bash

local_setup() {
	command -v zsh >/dev/null 2>&1 || skip "zsh is not installed"

	export TERM="xterm-256color"
	ZSH_SCRIPT="$BATS_TEST_TMPDIR/smoke.zsh"
	ZSH_OUT="$BATS_TEST_TMPDIR/zsh.out"
	ZSH_ERR="$BATS_TEST_TMPDIR/zsh.err"

	# The theme prints glyphs, which zsh refuses to do outside a UTF-8 locale
	local utf8_locale
	utf8_locale="$(locale -a 2>/dev/null | grep -i -m 1 -E '^(en_US|C)\.utf-?8$')"
	[[ -n "$utf8_locale" ]] && export LC_ALL="$utf8_locale"
	return 0
}

# Writes a script that sources the adapter and then runs the body from stdin.
_write_zsh_script() {
	{
		# shellcheck disable=SC2016
		printf '%s\n' 'source "$GAUDI_SHELL/adapters/zsh/init.zsh"'
		cat
	} >"$ZSH_SCRIPT"
}

# Runs the script, keeping standard output and standard error apart.
_run_zsh_script() {
	zsh -f "$ZSH_SCRIPT" >"$ZSH_OUT" 2>"$ZSH_ERR"
}

@test "zsh adapter: loads and runs the core commands without errors" {
	_write_zsh_script <<'SCRIPT'
print -r -- "shell=$GAUDI_SHELL_CURRENT"
gshell help
gshell enable alias general
gshell enable alias git
gshell show
gshell show aliases enabled
gshell disable alias git
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	assert_output ""

	run cat "$ZSH_OUT"
	assert_line "shell=zsh"
	assert_line --partial "Usage: gshell <command> [args]"
	assert_line --partial "enabled with priority"
	assert_line --regexp "^general +.*◉"
	assert_line --partial "◯ disabled"
}

@test "zsh adapter: enabled components are loaded" {
	ln -s "../aliases/general.aliases.bash" "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	cat >"$GAUDI_SHELL/components/aliases/zsh-smoke.aliases.bash" <<'ALIASES'
alias zsh_smoke_alias='echo smoke'
ALIASES
	ln -s "../aliases/zsh-smoke.aliases.bash" "$GAUDI_SHELL/components/enabled/150___zsh-smoke.aliases.bash"

	_write_zsh_script <<'SCRIPT'
alias zsh_smoke_alias
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_OUT"
	assert_line "zsh_smoke_alias='echo smoke'"
}

@test "zsh adapter: pathmunge changes PATH" {
	_write_zsh_script <<'SCRIPT'
PATH="/usr/bin:/bin"
pathmunge "/tmp/fake one:/tmp/fake-two"
print -r -- "prepend=$PATH"
pathmunge "/tmp/fake-two"
pathmunge "/tmp/fake-three" after
print -r -- "after=$PATH"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	assert_output ""
	run cat "$ZSH_OUT"
	assert_line "prepend=/tmp/fake one:/tmp/fake-two:/usr/bin:/bin"
	assert_line "after=/tmp/fake one:/tmp/fake-two:/usr/bin:/bin:/tmp/fake-three"
}

@test "zsh adapter: _read_input reads an answer and stops when there is none" {
	_write_zsh_script <<'SCRIPT'
print y | { _read_input "Sure?" >/dev/null; print -r -- "yes=$? reply=$REPLY"; }
print n | { _read_input "Sure?" >/dev/null; print -r -- "no=$? reply=$REPLY"; }
_read_input "Sure?" >/dev/null </dev/null
print -r -- "eof=$? reply=$REPLY"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	assert_output ""
	run cat "$ZSH_OUT"
	assert_line "yes=0 reply=y"
	assert_line "no=1 reply=n"
	assert_line "eof=2 reply="
}

@test "zsh adapter: backup, profile, help and search print no variable assignments" {
	_write_zsh_script <<'SCRIPT'
gshell enable alias general >/dev/null
gshell enable alias git >/dev/null
gshell enable plugin base >/dev/null
gshell enable plugin git >/dev/null
print -r -- "--- backup"
gshell backup
print -r -- "--- profile"
gshell profile save smoke
gshell profile save other
gshell profile list
gshell profile load smoke
print -r -- "--- help"
gshell help aliases
gshell help plugins
print -r -- "--- search"
gshell search git
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_OUT"
	assert_line "Backing up alias: general"
	assert_line "Backing up plugin: git"
	assert_line --partial "Profile saved:"
	refute_line --regexp '^_?[a-zA-Z_]+=[^ ]*$'

	run cat "$ZSH_ERR"
	refute_output --partial "read-only"
	refute_output --partial "bad option"
}

@test "zsh adapter: the gaudi theme renders a prompt with the default segments" {
	export GAUDI_SHELL_THEME="gaudi"
	_write_zsh_script <<'SCRIPT'
cd "$GAUDI_SHELL"
gaudi::prompt
print -r -- "PROMPT=$PROMPT"
print -r -- "LEFT=$_GAUDI_RENDERED_LEFT"
for segment in "${GAUDI_PROMPT_LEFT[@]}" "${GAUDI_PROMPT_RIGHT[@]}" "${GAUDI_PROMPT_ASYNC[@]}"; do
	(( ${+functions[gaudi_$segment]} )) || print -r -- "not loaded: $segment"
done
print -r -- "precmd=${precmd_functions[*]}"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_OUT"
	assert_output --partial "%F{2}>>%f "
	assert_line --partial "gaudi-shell"
	assert_line --partial "precmd=_gaudi_zsh_precmd"
	refute_output --partial "not loaded"

	run cat "$ZSH_ERR"
	refute_output --partial "command not found"
	refute_output --partial "bad substitution"
}

@test "zsh adapter: prompt text is never expanded again, with or without PROMPT_SUBST" {
	export GAUDI_SHELL_THEME="gaudi"
	export GAUDI_CWD_SHORTEN="false"

	local work="$BATS_TEST_TMPDIR/work"
	mkdir -p "$work"
	cd "$work"
	git init -q .
	git commit -q --allow-empty -m init
	# shellcheck disable=SC2016
	git checkout -q -b '$(touch${IFS}pwned-branch)'
	# shellcheck disable=SC2016
	mkdir -p '$(touch pwned-dir)/`touch pwned-tick`/100%F{red}%n'
	# shellcheck disable=SC2016
	cd '$(touch pwned-dir)/`touch pwned-tick`/100%F{red}%n'

	_write_zsh_script <<'SCRIPT'
GAUDI_PROMPT_LEFT=(cwd)
GAUDI_PROMPT_RIGHT=(user)
GAUDI_PROMPT_ASYNC=(scm)

unsetopt PROMPT_SUBST
gaudi::prompt
expanded="$(print -P -- "$PROMPT $RPROMPT")"
print -r -- "plain: ${expanded//$'\n'/ }"

setopt PROMPT_SUBST
gaudi::prompt
print -r -- "subst-prompt: ${PROMPT//$'\n'/ }"
expanded="$(print -P -- "$PROMPT $RPROMPT")"
print -r -- "subst: ${expanded//$'\n'/ }"
SCRIPT

	_run_zsh_script </dev/null

	run find "$work" -name 'pwned*' -type f
	assert_output ""

	run cat "$ZSH_OUT"
	# With PROMPT_SUBST the prompt only references the rendered text
	# shellcheck disable=SC2016
	assert_line --partial 'subst-prompt:  ${_GAUDI_RENDERED_LEFT}'
	# Hostile names and % sequences are displayed literally in both modes
	# shellcheck disable=SC2016
	assert_line --regexp '^plain: .*\$\(touch pwned-dir\)/`touch pwned-tick`/100%F\{red\}%n'
	# shellcheck disable=SC2016
	assert_line --regexp '^subst: .*\$\(touch pwned-dir\)/`touch pwned-tick`/100%F\{red\}%n'
}

@test "zsh adapter: theme segment files are sourced once, not on every prompt" {
	export GAUDI_SHELL_THEME="gaudi"
	export GAUDI_PROBE_LOG="$BATS_TEST_TMPDIR/probe.log"
	cat >"$GAUDI_SHELL/components/themes/bash/gaudi/segments/probe.bash" <<'SEGMENT'
echo "sourced" >>"$GAUDI_PROBE_LOG"
gaudi_probe() {
	printf 'probe-output'
}
SEGMENT

	_write_zsh_script <<'SCRIPT'
GAUDI_PROMPT_LEFT=(probe)
GAUDI_PROMPT_RIGHT=()
GAUDI_PROMPT_ASYNC=()
gaudi::prompt
gaudi::prompt
gaudi::prompt
print -r -- "LEFT=$_GAUDI_RENDERED_LEFT"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_OUT"
	assert_line "LEFT=probe-output"
	run cat "$GAUDI_PROBE_LOG"
	assert_output "sourced"
}

@test "zsh adapter: gshell update works and leaves the current directory alone" {
	(
		cd "$GAUDI_SHELL" || exit 1
		git init -q .
		git add -A
		GIT_AUTHOR_DATE="2020-01-01T12:00:00Z" GIT_COMMITTER_DATE="2020-01-01T12:00:00Z" git commit -q -m "one"
		git tag v0.0.1
		git clone -q --bare . "$BATS_TEST_TMPDIR/remote.git"
		git remote add origin "$BATS_TEST_TMPDIR/remote.git"
		git clone -q "$BATS_TEST_TMPDIR/remote.git" "$BATS_TEST_TMPDIR/other"
		cd "$BATS_TEST_TMPDIR/other" || exit 1
		GIT_AUTHOR_DATE="2021-01-01T12:00:00Z" GIT_COMMITTER_DATE="2021-01-01T12:00:00Z" git commit -q --allow-empty -m "two"
		git tag v0.0.2
		git push -q origin HEAD --tags
	) >/dev/null 2>&1
	mkdir -p "$BATS_TEST_TMPDIR/elsewhere"
	cd "$BATS_TEST_TMPDIR/elsewhere"

	_write_zsh_script <<'SCRIPT'
# Never re-exec the shell under test
_gaudi-shell-restart() { print -r -- "RESTART"; }
print n | gshell update
print -r -- "declined: pwd=${PWD:t} stack=${#dirstack}"
print y | gshell update
print -r -- "accepted: pwd=${PWD:t} stack=${#dirstack}"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	refute_output --partial "read-only variable"
	run cat "$ZSH_OUT"
	assert_line --partial "Not updating"
	assert_line "declined: pwd=elsewhere stack=0"
	assert_line --partial "gaudi-shell successfully updated."
	assert_line "RESTART"
	assert_line "accepted: pwd=elsewhere stack=0"
	assert_equal "$(git -C "$GAUDI_SHELL" describe --tags)" "v0.0.2"
}

@test "zsh adapter: error paths return non-zero" {
	_write_zsh_script <<'SCRIPT'
gshell frobnicate; print -r -- "unknown=$?"
gshell; print -r -- "empty=$?"
gshell restore; print -r -- "restore=$?"
gshell enable alias no-such-alias; print -r -- "enable=$?"
gshell disable alias general; print -r -- "disable=$?"
gshell profile load nope; print -r -- "profile=$?"
gshell show aliases enabled >/dev/null; print -r -- "show=$?"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_OUT"
	assert_line "unknown=1"
	assert_line "empty=1"
	assert_line "restore=1"
	assert_line "enable=1"
	assert_line "disable=1"
	assert_line "profile=1"
	assert_line "show=0"
	run cat "$ZSH_ERR"
	assert_output "gshell: unknown command 'frobnicate'"
}

@test "zsh adapter: profile load checks the profile before disabling anything" {
	_write_zsh_script <<'SCRIPT'
gshell enable alias general >/dev/null
gshell enable plugin base >/dev/null
mkdir -p "$GAUDI_SHELL/profiles"
print -r -- "alias git" "plugin no-such-plugin" | tr ' ' '\n' | paste -d ' ' - - >"$GAUDI_SHELL/profiles/broken.gaudi-shell"
gshell profile load broken
print -r -- "status=$?"
print -r -- "enabled=$(cd "$GAUDI_SHELL/components/enabled" && print -r -- *)"
gshell backup >/dev/null
gshell disable alias general >/dev/null
gshell restore >/dev/null
print -r -- "restored=$(cd "$GAUDI_SHELL/components/enabled" && print -r -- *)"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	assert_output ""
	run cat "$ZSH_OUT"
	assert_line --partial "Unknown plugin"
	assert_line --partial "nothing was changed"
	assert_line "status=1"
	assert_line "enabled=150___general.aliases.bash 250___base.plugins.bash"
	assert_line "restored=150___general.aliases.bash 250___base.plugins.bash"
}

@test "zsh adapter: the completion dump directory is created and compinit runs once" {
	export XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"

	_write_zsh_script <<'SCRIPT'
print -r -- "compdef=${+functions[compdef]}"
SCRIPT
	_run_zsh_script </dev/null

	run cat "$ZSH_OUT"
	assert_line "compdef=1"
	assert_file_exist "$XDG_CACHE_HOME/gaudi-shell/zcompdump"

	# With compdef already defined (the user ran compinit), it is not run again
	export XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache2"
	{
		printf '%s\n' 'compdef() { print -r -- "compdef called: $*"; }' 'compinit() { print -r -- "compinit called again"; }'
		# shellcheck disable=SC2016
		printf '%s\n' 'source "$GAUDI_SHELL/adapters/zsh/init.zsh"' 'print -r -- "loaded"'
	} >"$ZSH_SCRIPT"
	_run_zsh_script </dev/null

	run cat "$ZSH_OUT"
	assert_line "loaded"
	refute_output --partial "compinit called again"
	assert_dir_not_exist "$XDG_CACHE_HOME/gaudi-shell"
}

@test "zsh adapter: history is kept: sizes raised, a history file and SAVEHIST set" {
	_write_zsh_script <<'SCRIPT'
print -r -- "sizes=$HISTSIZE/$SAVEHIST file=${HISTFILE:t}"
HISTSIZE=99999 SAVEHIST=5 HISTFILE=/somewhere/else
source "$GAUDI_SHELL/lib/history.bash"
print -r -- "again=$HISTSIZE/$SAVEHIST file=$HISTFILE"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	assert_output ""
	run cat "$ZSH_OUT"
	assert_line "sizes=10000/20000 file=.zsh_history"
	assert_line "again=99999/20000 file=/somewhere/else"
}

@test "zsh adapter: gshell completion offers the commands, arguments and flags of the command table" {
	ln -s "../completions/gaudi-shell.completions.bash" "$GAUDI_SHELL/components/enabled/350___gaudi-shell.completions.bash"
	ln -s "../aliases/general.aliases.bash" "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	mkdir -p "$GAUDI_SHELL/profiles"
	echo "alias general" >"$GAUDI_SHELL/profiles/work.gaudi-shell"

	_write_zsh_script <<'SCRIPT'
# Outside the line editor: show what would be offered
compadd() { shift; print -r -- "$label: $*"; }
complete_at() { label="$1"; shift; words=("$@"); CURRENT=${#words}; _gaudi-shell-zsh-comp; }
setopt nomatch
complete_at top gshell ""
complete_at show gshell show ""
complete_at show-type gshell show aliases ""
complete_at search gshell search git ""
complete_at enable gshell enable ""
complete_at enable-alias gshell enable alias ""
complete_at disable-alias gshell disable alias ""
complete_at profile gshell profile ""
complete_at profile-load gshell profile load ""
complete_at reload gshell reload ""
print -r -- "verbs=$(_gaudi-shell-verb-names)"
[[ -o nomatch ]] && print -r -- "options restored"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	assert_output ""
	run cat "$ZSH_OUT"
	assert_line "top: show enable disable search help profile backup restore update doctor reload restart version"
	assert_line "show: aliases plugins completions"
	assert_line "show-type: enabled"
	assert_line "search: --enable --disable --plugin --alias --completion --no-color --refresh --help"
	assert_line "enable: alias plugin completion"
	assert_line --regexp '^enable-alias: all .*git'
	refute_line --regexp '^enable-alias: .* general( |$)'
	assert_line "disable-alias: all general"
	assert_line "profile: save load list rm"
	assert_line --regexp '^profile-load: .*work'
	refute_line --partial "reload:"
	assert_line "options restored"
}

@test "zsh adapter: the scm segment renders the same git states as in bash" {
	export GAUDI_SHELL_THEME="gaudi"
	export SCM_REPOS="$BATS_TEST_TMPDIR/repos"
	_make_scm_repos "$SCM_REPOS"

	{
		_scm_render_script
		cat <<'SCRIPT'
cd "$SCM_REPOS/clean"
git config user.name "Ada Maria Lovelace"
GAUDI_SCM_GIT_SHOW_CURRENT_USER=true
scm_prompt_vars
print -r -- "user=$GAUDI_SCM_BRANCH"
SCRIPT
	} | _write_zsh_script

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	assert_output ""
	run cat "$ZSH_OUT"
	_assert_scm_states
	# One initial per word of the name
	assert_line "user=main@ aml"
}

@test "zsh adapter: cwd shortening works and leaves PATH alone" {
	export GAUDI_SHELL_THEME="gaudi"
	_write_zsh_script <<'SCRIPT'
before="$PATH"
HOME=/Users/tester
for dir in / /Users/tester/x \
	/Users/tester/aaaaaaaaaaaa/bbbbbbbbbbbb/cc/dddddddddddd \
	/Users/tester/Projects/some-client/website/src/components/buttons \
	/usr/local/share/very-long-directory-name/another-long-one/leaf; do
	print -r -- "[$(gaudi::shorten_path "$dir")]"
done
[[ "$PATH" == "$before" ]] && print -r -- "PATH intact"
(( ${#path} > 1 )) && print -r -- "path array intact"
GAUDI_CWD_SHORTEN=true
cd "$GAUDI_SHELL/components/themes/bash/gaudi/segments"
print -r -- "segment=$(gaudi_cwd)"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	assert_output ""
	run cat "$ZSH_OUT"
	assert_line "[⚠ ROOT]"
	assert_line "[~/x]"
	assert_line "[~/a/bbbbbbbbbbbb/cc/dddddddddddd]"
	assert_line "[~/P/s/website/src/c/buttons]"
	assert_line "[/usr/local/share/v/a/leaf]"
	assert_line "PATH intact"
	assert_line "path array intact"
	# The real directory is far longer than the limit, and ends with its own name in full
	assert_line --regexp '^segment=.*/segments'
	refute_line --partial "components/themes/bash/gaudi/segments"
}

@test "zsh adapter: docker COMPOSE_FILE, has_files and the continuation prompt work" {
	export GAUDI_SHELL_THEME="gaudi"
	local fakebin="$BATS_TEST_TMPDIR/fakebin" work="$BATS_TEST_TMPDIR/compose"
	mkdir -p "$fakebin" "$work/empty"
	printf '%s\n' '#!/usr/bin/env bash' 'echo "27.1.0-rc1"' >"$fakebin/docker"
	chmod +x "$fakebin/docker"
	touch "$work/one.yml" "$work/two.yml" "$work/app.js"
	export FAKEBIN="$fakebin" WORK="$work"

	_write_zsh_script <<'SCRIPT'
path=("$FAKEBIN" $path)
# The user's own option: a pattern without matches is an error
setopt nomatch
cd "$WORK"
gaudi::load_segment docker
COMPOSE_FILE="one.yml:two.yml"
print -r -- "both=$(gaudi_docker)"
COMPOSE_FILE="one.yml:missing.yml"
print -r -- "missing=[$(gaudi_docker)]"
unset COMPOSE_FILE
gaudi::has_files js && print -r -- "js: yes"
gaudi::has_files go rs || print -r -- "go: no"
cd "$WORK/empty" && { gaudi::has_files js || print -r -- "empty: no"; }
gaudi::load_segment char
print -r -- "symbols=[$GAUDI_CHAR_SYMBOL] continuation-set=${+GAUDI_CONTINUATION_SYMBOL}"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	assert_output ""
	run cat "$ZSH_OUT"
	assert_line --partial "27.1.0"
	assert_line "missing=[]"
	assert_line "js: yes"
	assert_line "go: no"
	assert_line "empty: no"
	assert_line "symbols=[>>] continuation-set=1"
}
