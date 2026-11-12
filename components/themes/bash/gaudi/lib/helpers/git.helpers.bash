#!/usr/bin/env bash
# shellcheck shell=bash
# The GAUDI_SCM_* variables set here are read by lib/scm.bash and segments/scm.bash.
# shellcheck disable=SC2034

GAUDI_SCM_GIT_SHOW_DETAILS=${GAUDI_SCM_GIT_SHOW_DETAILS:=true}
GAUDI_SCM_GIT_SHOW_REMOTE_INFO=${GAUDI_SCM_GIT_SHOW_REMOTE_INFO:=auto}
GAUDI_SCM_GIT_IGNORE_UNTRACKED=${GAUDI_SCM_GIT_IGNORE_UNTRACKED:=false}
GAUDI_SCM_GIT_IGNORE_SUBMODULES=${GAUDI_SCM_GIT_IGNORE_SUBMODULES:=true}
GAUDI_SCM_GIT_SHOW_CURRENT_USER=${GAUDI_SCM_GIT_SHOW_CURRENT_USER:=false}
GAUDI_SCM_GIT_SHOW_COMMIT_SHA=${GAUDI_SCM_GIT_SHOW_COMMIT_SHA:=false}

GAUDI_SCM_GIT='git'
GAUDI_SCM_GIT_CHAR=${GAUDI_SCM_GIT_CHAR:=git}
GAUDI_SCM_GIT_USER_CHAR=${GAUDI_SCM_GIT_USER_CHAR:=@}
GAUDI_SCM_GIT_AHEAD_CHAR=${GAUDI_SCM_GIT_AHEAD_CHAR:=^}
GAUDI_SCM_GIT_BEHIND_CHAR=${GAUDI_SCM_GIT_BEHIND_CHAR:=v}
GAUDI_SCM_GIT_UNTRACKED_CHAR=${GAUDI_SCM_GIT_UNTRACKED_CHAR:=?:}
GAUDI_SCM_GIT_CHANGED_CHAR=${GAUDI_SCM_GIT_CHANGED_CHAR:=!:}
GAUDI_SCM_GIT_STAGED_CHAR=${GAUDI_SCM_GIT_STAGED_CHAR:=+:}
GAUDI_SCM_GIT_CONFLICTED_CHAR=${GAUDI_SCM_GIT_CONFLICTED_CHAR:=x:}
GAUDI_SCM_GIT_STASH_CHAR=${GAUDI_SCM_GIT_STASH_CHAR:=*:}
GAUDI_SCM_GIT_SHA_CHAR=${GAUDI_SCM_GIT_SHA_CHAR:=#:}
GAUDI_SCM_GIT_GONE_CHAR=${GAUDI_SCM_GIT_GONE_CHAR:=gone}

# Normalize the previously shipped defaults when the theme is re-sourced in an
# already-running shell. This preserves intentional user overrides while
# replacing the old broken literal escape strings.
[[ "${GAUDI_SCM_GIT_CHAR}" == "\\ue727" ]] && GAUDI_SCM_GIT_CHAR="git"
[[ "${GAUDI_SCM_GIT_USER_CHAR}" == "\\uf7a3" ]] && GAUDI_SCM_GIT_USER_CHAR="@"
[[ "${GAUDI_SCM_GIT_UNTRACKED_CHAR}" == "\\uf070 " ]] && GAUDI_SCM_GIT_UNTRACKED_CHAR="?:"
[[ "${GAUDI_SCM_GIT_CHANGED_CHAR}" == "U:" ]] && GAUDI_SCM_GIT_CHANGED_CHAR="!:"
[[ "${GAUDI_SCM_GIT_STAGED_CHAR}" == "S:" ]] && GAUDI_SCM_GIT_STAGED_CHAR="+:"
[[ "${GAUDI_SCM_GIT_STASH_CHAR}" == "\\uf5e1" ]] && GAUDI_SCM_GIT_STASH_CHAR="*:"
[[ "${GAUDI_SCM_GIT_SHA_CHAR}" == "\\uf417" ]] && GAUDI_SCM_GIT_SHA_CHAR="#:"
[[ "${GAUDI_SCM_THEME_DETACHED_PREFIX}" == "⌿" ]] && GAUDI_SCM_THEME_DETACHED_PREFIX="detached:"

# True when the repository asks for its status to be hidden:
#   git config gaudi-shell.hide-status 1
# The key used before the rename (gaudi-bash.hide-status) is still honoured.
function _git-hide-status() {
	[[ "$(git config --get gaudi-shell.hide-status 2> /dev/null)" == "1" ]] && return 0
	[[ "$(git config --get gaudi-bash.hide-status 2> /dev/null)" == "1" ]]
}

# Name of the operation in progress in the git directory "$1", if any.
function _git-operation() {
	local git_dir="$1"

	[[ -n "$git_dir" ]] || return 1

	if [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ]]; then
		echo "rebase"
	elif [[ -f "$git_dir/MERGE_HEAD" ]]; then
		echo "merge"
	elif [[ -f "$git_dir/CHERRY_PICK_HEAD" ]]; then
		echo "cherry"
	elif [[ -f "$git_dir/REVERT_HEAD" ]]; then
		echo "revert"
	elif [[ -f "$git_dir/BISECT_LOG" ]]; then
		echo "bisect"
	else
		return 1
	fi
}

git_user_info () {
  local git_user_name=""
  local git_user_initials=""
  local word=""

  # support two or more initials, set by 'git pair' plugin
  GAUDI_SCM_CURRENT_USER="$(git config user.initials | sed 's% %+%')"

  if [[ -z "${GAUDI_SCM_CURRENT_USER}" ]]; then
    git_user_name="$(git config user.name | PERLIO=:utf8 perl -pe '$_=lc')"
    # Split on spaces by hand: zsh does not word-split an unquoted variable.
    while [[ -n "$git_user_name" ]]; do
      word="${git_user_name%% *}"
      git_user_initials+="${word:0:1}"
      if [[ "$git_user_name" == *" "* ]]; then
        git_user_name="${git_user_name#* }"
      else
        git_user_name=""
      fi
    done
    GAUDI_SCM_CURRENT_USER="$git_user_initials"
  fi

  [[ -n "${GAUDI_SCM_CURRENT_USER}" ]] && printf "%b" "$GAUDI_SCM_GIT_USER_CHAR $GAUDI_SCM_CURRENT_USER"
}

# Fill GAUDI_SCM_BRANCH, GAUDI_SCM_STATE and GAUDI_SCM_DIRTY.
#
# This runs on every prompt, so it is kept to a handful of git processes:
#   1. git status --porcelain=v2 --branch   branch, upstream, ahead/behind, counts
#   2. git rev-parse --git-dir --short HEAD  operation in progress, short sha
#   3. git rev-list ... refs/stash           stash count
#   4. git remote                            only with an upstream and
#                                            GAUDI_SCM_GIT_SHOW_REMOTE_INFO=auto
# A detached HEAD needs one or two "git describe" calls on top of that.
git_prompt_vars () {
  local commits_behind=0
  local commits_ahead=0
  local stash_count=0
  local num_untracked=0
  local num_changed=0
  local num_staged=0
  local num_conflicted=0
  local num_remotes=0
  local upstream_gone=0
  local has_ahead_behind=false
  local head_oid=""
  local branch=""
  local upstream=""
  local upstream_branch=""
  local same_branch_name=false
  local remote_info=""
  local git_dir=""
  local short_sha=""
  local git_operation=""
  local detached_prefix=""
  local detached_ref=""
  local working_tree_dirty=false
  local status_line=""
  local -a git_status_flags
  git_status_flags=("--porcelain=v2" "--branch")

  # Make sure we do a fetch to get all the information needed form the upstream
  [[ $GAUDI_SCM_FETCH == true ]] && git fetch &> /dev/null;

  [[ "${GAUDI_SCM_GIT_IGNORE_UNTRACKED:-}" == "true" ]] && git_status_flags+=("-uno")
  [[ "${GAUDI_SCM_GIT_IGNORE_SUBMODULES:-}" == "true" ]] && git_status_flags+=("--ignore-submodules=dirty")

  # Header lines start with "# branch."; then one line per entry:
  #   "1 XY ..." changed, "2 XY ..." renamed or copied, "u XY ..." unmerged,
  #   "? path" untracked. X is the staged state, Y the work tree state and "."
  #   means unchanged.
  while IFS= read -r status_line; do
    case "$status_line" in
      '# branch.oid '*) head_oid=${status_line#"# branch.oid "} ;;
      '# branch.head '*) branch=${status_line#"# branch.head "} ;;
      '# branch.upstream '*) upstream=${status_line#"# branch.upstream "} ;;
      '# branch.ab '*)
        # "# branch.ab +<ahead> -<behind>", only printed when the upstream exists
        has_ahead_behind=true
        status_line=${status_line#"# branch.ab +"}
        commits_ahead=${status_line%% *}
        commits_behind=${status_line##*-}
        ;;
      '? '*) num_untracked=$((num_untracked + 1)) ;;
      'u '*) num_conflicted=$((num_conflicted + 1)) ;;
      [12]' '*)
        [[ "${status_line:2:1}" != "." ]] && num_staged=$((num_staged + 1))
        [[ "${status_line:3:1}" != "." ]] && num_changed=$((num_changed + 1))
        ;;
    esac
  done < <(git status "${git_status_flags[@]}" 2> /dev/null)

  # First line: the git directory. Second line: the short sha, missing in a
  # repository without commits.
  {
    IFS= read -r git_dir
    IFS= read -r short_sha
  } < <(git rev-parse --git-dir --short HEAD 2> /dev/null)

  if [[ "$branch" != "(detached)" ]]; then
    GAUDI_SCM_BRANCH="$branch"

    if [[ -n "$upstream" ]]; then
      # "origin/feature/x" tracks the branch "feature/x"
      [[ "$upstream" == */* ]] && upstream_branch="${upstream#*/}"
      [[ "$branch" == "$upstream_branch" ]] && same_branch_name=true

      if [[ "${GAUDI_SCM_GIT_SHOW_REMOTE_INFO}" == "auto" ]]; then
        while IFS= read -r status_line; do
          num_remotes=$((num_remotes + 1))
        done < <(git remote 2> /dev/null)
      fi

      if [[ "${GAUDI_SCM_GIT_SHOW_REMOTE_INFO}" == "true" ]] ||
        { [[ "${GAUDI_SCM_GIT_SHOW_REMOTE_INFO}" == "auto" ]] && [[ "$num_remotes" -ge 2 ]]; }; then
        if [[ "$same_branch_name" == true ]]; then
          remote_info="${upstream%"/${upstream_branch}"}"
        else
          remote_info="$upstream"
        fi
      elif [[ "$same_branch_name" != true ]]; then
        remote_info="$upstream_branch"
      fi

      [[ -n "$remote_info" ]] && GAUDI_SCM_BRANCH+=" → $remote_info"

      # An upstream is configured but its ref no longer exists
      [[ "$has_ahead_behind" == false && "$head_oid" != "(initial)" ]] && upstream_gone=1
    fi
  else
    if detached_ref="$(git describe --tags --exact-match 2> /dev/null)"; then
      detached_prefix="${GAUDI_SCM_THEME_TAG_PREFIX}"
    else
      detached_prefix="${GAUDI_SCM_THEME_DETACHED_PREFIX}"
      detached_ref="$(git describe --contains --all 2> /dev/null)" || detached_ref="$short_sha"
    fi
    GAUDI_SCM_BRANCH="${detached_prefix}${detached_ref}"
  fi

  [[ "${commits_ahead:-0}" -gt 0 ]] && GAUDI_SCM_BRANCH+=" ${GAUDI_SCM_GIT_AHEAD_CHAR}${commits_ahead}"
  [[ "${commits_behind:-0}" -gt 0 ]] && GAUDI_SCM_BRANCH+=" ${GAUDI_SCM_GIT_BEHIND_CHAR}${commits_behind}"
  [[ "${upstream_gone:-0}" == 1 ]] && GAUDI_SCM_BRANCH+=" ${GAUDI_SCM_GIT_GONE_CHAR}"

  git_operation="$(_git-operation "$git_dir" 2> /dev/null || true)"
  [[ -n "${git_operation}" ]] && GAUDI_SCM_BRANCH+=" ${git_operation}"

  stash_count="$(git rev-list --walk-reflogs --count refs/stash 2> /dev/null || echo 0)"
  [[ "${stash_count:-0}" -gt 0 ]] && GAUDI_SCM_BRANCH+=" ${GAUDI_SCM_GIT_STASH_CHAR}${stash_count}"

  GAUDI_SCM_STATE=${GIT_THEME_PROMPT_CLEAN:-$GAUDI_SCM_THEME_PROMPT_CLEAN}

  if [[ "${num_staged}" -gt 0 || "${num_changed}" -gt 0 || "${num_untracked}" -gt 0 || "${num_conflicted}" -gt 0 ]]; then
    working_tree_dirty=true

    if [[ "${GAUDI_SCM_GIT_SHOW_DETAILS}" = "true" ]]; then
      [[ "${num_staged}" -gt 0 ]] && GAUDI_SCM_BRANCH+=" ${GAUDI_SCM_GIT_STAGED_CHAR}${num_staged}"
      [[ "${num_changed}" -gt 0 ]] && GAUDI_SCM_BRANCH+=" ${GAUDI_SCM_GIT_CHANGED_CHAR}${num_changed}"
      [[ "${num_untracked}" -gt 0 ]] && GAUDI_SCM_BRANCH+=" ${GAUDI_SCM_GIT_UNTRACKED_CHAR}${num_untracked}"
      [[ "${num_conflicted}" -gt 0 ]] && GAUDI_SCM_BRANCH+=" ${GAUDI_SCM_GIT_CONFLICTED_CHAR}${num_conflicted}"
      GAUDI_SCM_STATE=""
    else
      GAUDI_SCM_STATE=${GIT_THEME_PROMPT_DIRTY:-$GAUDI_SCM_THEME_PROMPT_DIRTY}
    fi
  else
    GAUDI_SCM_STATE=${GIT_THEME_PROMPT_CLEAN:-$GAUDI_SCM_THEME_PROMPT_CLEAN}
  fi

  if [[ "${num_conflicted}" -gt 0 ]]; then
    GAUDI_SCM_DIRTY=4
  elif [[ "${working_tree_dirty}" == "true" ]]; then
    if [[ "${num_changed}" -gt 0 || "${num_untracked}" -gt 0 ]]; then
      GAUDI_SCM_DIRTY=2
    else
      GAUDI_SCM_DIRTY=3
    fi
  fi

  if [[ "${GAUDI_SCM_GIT_SHOW_COMMIT_SHA}" == true ]]; then
    GAUDI_SCM_BRANCH+=" ${GAUDI_SCM_GIT_SHA_CHAR}${short_sha}"
  fi
  [[ "${GAUDI_SCM_GIT_SHOW_CURRENT_USER}" == "true" ]] && GAUDI_SCM_BRANCH+="$(git_user_info)"
}
