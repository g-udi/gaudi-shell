#!/usr/bin/env bash
# shellcheck shell=bash

# @function     _gaudi-shell_update_and_restart
# @description  Checks out the wanted version, pops directory and restart
# @param $1     (optional) Which branch to checkout to
# @param $2     (optional) Which type of version we are using
# @example      ❯ _gaudi-shell_update_and_restarts
function _gaudi-shell_update_and_restart() {
	about 'Checks out the wanted version, pops directory and restart. Does not return (because of the restart!)'
	group 'gaudi-shell:core:updater'

	# Called with the install directory pushed by _gaudi-shell-update: every
	# path out of here pops it again, so the user is never left in there.
	if git checkout "$1" &>/dev/null; then
		echo "gaudi-shell successfully updated."
		popd &>/dev/null || return
		_gaudi-shell-restart
	else
		echo "Error updating gaudi-shell, please, check if your gaudi-shell installation folder (${GAUDI_SHELL}) is clean."
		popd &>/dev/null || return 1
		return 1
	fi
}

# @function      _gaudi-shell-update
# @description  Updates gaudi-shell
# @param $1     (optional) What kind of update to do (stable|dev)
# @example      ❯  _gaudi-shell-update
function _gaudi-shell-update() {
	about 'updates gaudi-shell'
	group 'gaudi-shell:core:updater'

	# Not named "status": that is a read-only special variable in zsh.
	local silent word mode DIFF version TARGET revision pending revert log_color RESP
	for word in "$@"; do
		if [[ "${word}" == "--silent" || "${word}" == "-s" ]]; then
			silent=true
		elif [[ -z "${mode:-}" ]]; then
			# The first word that is not a flag is the update mode
			mode="${word}"
		fi
	done

	pushd "${GAUDI_SHELL?}" >/dev/null || return

	DIFF=$(git diff --name-status)
	if [[ -n "$DIFF" ]]; then
		echo -e "Local changes detected in gaudi-shell directory. Clean '$GAUDI_SHELL' directory to proceed.\n$DIFF"
		popd >/dev/null || return
		return 1
	fi

	if [[ -z "$GAUDI_SHELL_REMOTE" ]]; then
		GAUDI_SHELL_REMOTE="origin"
	fi

	if ! git fetch "$GAUDI_SHELL_REMOTE" --tags &>/dev/null; then
		echo "Could not fetch from '$GAUDI_SHELL_REMOTE': check the network and the remote, then try again."
		popd >/dev/null || return 1
		return 1
	fi

	if [[ -z "$GAUDI_SHELL_DEVELOPMENT_BRANCH" ]]; then
		GAUDI_SHELL_DEVELOPMENT_BRANCH="main"
	fi

	if [[ -z "${mode:-}" || "${mode}" == "stable" ]]; then
		version="stable"
		TARGET=$(git describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null)

		if [[ -z "$TARGET" ]]; then
			echo "Can not find tags, so can not update to latest stable version..."
			popd >/dev/null || return
			return 1
		fi
	else
		version="dev"
		TARGET="${GAUDI_SHELL_REMOTE}/${GAUDI_SHELL_DEVELOPMENT_BRANCH}"
	fi

	revision="HEAD..${TARGET}"
	pending="$(git rev-list "${revision}" 2>/dev/null)"

	if [[ -z "${pending}" && "${version}" == "stable" ]]; then
		revision="${TARGET}..HEAD"
		pending="$(git rev-list "${revision}" 2>/dev/null)"
		revert=true
	fi

	if [[ -n "${pending}" ]]; then
		if [[ -n "${revert}" ]]; then
			echo "Your version is a more recent development version ($(git log -1 --format=%h HEAD))"
			echo "You can continue in order to revert and update to the latest stable version"
			echo ""
			log_color="%Cred"
		fi

		git log --no-merges --format="${log_color}%h: %s (%an)" "${revision}"
		echo ""

		if [[ -n "${silent}" ]]; then
			echo "Updating to ${TARGET}($(git log -1 --format=%h "${TARGET}"))..."
			# Pops the directory itself, on success and on failure.
			_gaudi-shell_update_and_restart "$TARGET" "$version"
			return
		else
			# printf + plain read works in both bash and zsh (read -e -n -p is bash-only)
			printf '%s' "Would you like to update to ${TARGET}($(git log -1 --format=%h "${TARGET}"))? [Y/n] "
			# No answer at all (end of input, no terminal) is not a "yes".
			read -r RESP || RESP="n"
			case "$RESP" in
			[yY]* | "")
				_gaudi-shell_update_and_restart "$TARGET" "$version"
				return
				;;
			[nN]*)
				echo "Not updating…"
				;;
			*)
				echo -e "${ORANGE:-}Please choose y or n.${NC:-}"
				;;
			esac
		fi
	else
		if [[ "${version}" == "stable" ]]; then
			echo "You're on the latest stable version. If you want to check out the latest 'dev' version, please run \"gshell update dev\""
		else
			echo "gaudi-shell is up to date, nothing to do!"
		fi
	fi
	popd >/dev/null || return
}
