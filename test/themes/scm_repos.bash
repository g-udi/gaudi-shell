#!/usr/bin/env bash
# shellcheck shell=bash
#
# Sample git repositories for the scm segment, shared by the bash theme tests
# and the zsh smoke tests: both shells must render the same text for each.

# Creates the sample repositories under $1.
_make_scm_repos() {
	local root="$1"
	mkdir -p "$root"
	(
		cd "$root" || exit 1
		export GIT_CONFIG_NOSYSTEM=1

		git init -q -b main origin
		(
			cd origin || exit 1
			echo a >a
			echo b >b
			git add .
			git commit -q -m one
			echo c >c
			git add c
			git commit -q -m two
			git branch feature
		)

		git clone -q origin clean
		git clone -q origin dirty && (cd dirty && echo x >>a)
		git clone -q origin staged && (cd staged && echo x >>a && git add a)
		git clone -q origin untracked && (cd untracked && echo n >new1 && echo n >new2)
		git clone -q origin mixed && (cd mixed && echo x >>a && git add a && echo y >>b && echo n >new && git mv c d)
		git clone -q origin ahead && (cd ahead && echo x >x && git add x && git commit -q -m x && echo y >y && git add y && git commit -q -m y)
		git clone -q origin behind && (cd behind && git reset -q --hard HEAD~1)
		git clone -q origin diverged && (cd diverged && git reset -q --hard HEAD~1 && echo q >q && git add q && git commit -q -m q)
		git clone -q origin detached && (cd detached && git -c advice.detachedHead=false checkout -q HEAD~1)
		git clone -q origin tagged && (cd tagged && git tag v1.0 && git -c advice.detachedHead=false checkout -q v1.0)
		git clone -q origin noupstream && (cd noupstream && git checkout -q -b local-only)
		git clone -q origin gone && (cd gone && git checkout -q -b doomed && git push -q -u origin doomed && git push -q origin :doomed && git fetch -q --prune && echo x >>a)
		git clone -q origin stash && (cd stash && echo x >>a && git stash -q)
		git clone -q origin othername && (cd othername && git checkout -q -b mine --track origin/feature)
		git clone -q origin conflict && (
			cd conflict || exit 1
			git checkout -q -b side
			echo s >a
			git commit -q -a -m side
			git checkout -q main
			echo m >a
			git commit -q -a -m m
			git merge -q side || true
		)
		git clone -q origin nested && mkdir -p nested/deep/er
		git init -q -b main unborn
	) >/dev/null 2>&1
}

# Prints a script body (valid in bash and zsh, to run after the adapter and the
# gaudi theme are loaded) that renders the scm state of every sample
# repository under $SCM_REPOS as "<name>=<branch text>|<dirty level>".
_scm_render_script() {
	cat <<'SCRIPT'
for repo in clean dirty staged untracked mixed ahead behind diverged detached tagged noupstream gone stash othername conflict nested/deep/er unborn; do
	cd "$SCM_REPOS/$repo" || continue
	GAUDI_SCM_BRANCH=""
	scm_prompt_vars
	printf '%s=%s|%s\n' "$repo" "$GAUDI_SCM_BRANCH" "$GAUDI_SCM_DIRTY"
done
SCRIPT
}

# Asserts on the lines printed by the script above (in $output).
_assert_scm_states() {
	assert_line "clean=main|0"
	assert_line "dirty=main !:1|2"
	assert_line "staged=main +:1|3"
	assert_line "untracked=main ?:2|2"
	assert_line "mixed=main +:2 !:1 ?:1|2"
	assert_line "ahead=main ^2|0"
	assert_line "behind=main v1|0"
	assert_line "diverged=main ^1 v1|0"
	assert_line --regexp '^detached=detached:[^ ]+\|0$'
	assert_line "tagged=tag:v1.0|0"
	assert_line "noupstream=local-only|0"
	# The upstream was deleted; the marker shows on a dirty tree too
	assert_line "gone=doomed gone !:1|2"
	assert_line "stash=main *:1|0"
	assert_line "othername=mine → feature|0"
	assert_line "conflict=main ^1 merge x:1|4"
	assert_line "nested/deep/er=main|0"
	assert_line "unborn=main|0"
}
