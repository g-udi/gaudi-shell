#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC1090,SC1091,SC2034

# gaudi-shell — cross-shell framework for bash and zsh
# Entry point: source this from your shell's init file via the adapter.

GAUDI_SHELL_LOG_PREFIX="CORE"
# GAUDI_SHELL should be set by the adapter; fallback to BASH_SOURCE for direct sourcing
if [[ -z "${GAUDI_SHELL:-}" ]]; then
	if [[ -n "${BASH_SOURCE:-}" ]]; then
		GAUDI_SHELL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	fi
fi

# Detect current shell
if [[ -n "$ZSH_VERSION" ]]; then
	GAUDI_SHELL_CURRENT="zsh"
else
	GAUDI_SHELL_CURRENT="bash"
fi
export GAUDI_SHELL_CURRENT

# Determine profile file
case $OSTYPE in
darwin*)
	export GAUDI_SHELL_PROFILE=".bash_profile"
	[[ "$GAUDI_SHELL_CURRENT" == "zsh" ]] && export GAUDI_SHELL_PROFILE=".zshrc"
	;;
*)
	export GAUDI_SHELL_PROFILE=".bashrc"
	[[ "$GAUDI_SHELL_CURRENT" == "zsh" ]] && export GAUDI_SHELL_PROFILE=".zshrc"
	;;
esac

# Finalize hook array — plugins can append callbacks to run after all loading
GAUDI_SHELL_FINALIZE_HOOKS=()

# Load core libraries
source "${GAUDI_SHELL}/lib/log.bash"
source "${GAUDI_SHELL}/lib/colors.bash"

for _gs_lib in "${GAUDI_SHELL}"/lib/*.bash; do
	[[ "$_gs_lib" == */appearance.bash ]] && continue
	[[ "$_gs_lib" == */log.bash ]] && continue
	[[ "$_gs_lib" == */colors.bash ]] && continue
	_log_component "$_gs_lib" "library"
	source "$_gs_lib"
done
unset _gs_lib

# Load all helper libraries
for _gs_helper in "${GAUDI_SHELL}"/lib/helpers/*.bash; do
	source "$_gs_helper"
done
unset _gs_helper

# Load enabled components (sorted by priority via glob)
source "${GAUDI_SHELL}/scripts/loader.bash"

# Load local custom components after enabled components.
: "${GAUDI_SHELL_CUSTOM:=${GAUDI_SHELL}/components/custom}"
: "${GAUDI_SHELL_CUSTOM_PATHS:=$GAUDI_SHELL_CUSTOM}"
while IFS= read -r _gs_custom_dir; do
	[[ -n "$_gs_custom_dir" && -d "$_gs_custom_dir" ]] || continue
	while IFS= read -r _gs_custom; do
		_log_component "$_gs_custom" "custom"
		source "$_gs_custom"
	done < <(find "$_gs_custom_dir" -type f -name '*.bash' | sort)
done < <(printf "%s\n" "$GAUDI_SHELL_CUSTOM_PATHS" | tr ':' '\n')
unset _gs_custom _gs_custom_dir

# Load appearance/theme
[[ -f "${GAUDI_SHELL}/lib/appearance.bash" ]] && source "${GAUDI_SHELL}/lib/appearance.bash"

# Run finalize hooks
for _gs_hook in "${GAUDI_SHELL_FINALIZE_HOOKS[@]}"; do
	"$_gs_hook"
done
unset _gs_hook

# Disable DEBUG trap on subshells (bash-specific)
[[ "$GAUDI_SHELL_CURRENT" == "bash" ]] && set +T
