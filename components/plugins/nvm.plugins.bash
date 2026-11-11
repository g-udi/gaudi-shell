# shellcheck shell=bash
# shellcheck disable=SC1090

cite about-plugin priority
about-plugin 'Node version manager configuration (lazy-loaded for fast startup)'
priority "250"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# Lazy-load nvm: define stub functions that load the real nvm on first use.
# This avoids sourcing nvm.sh at shell startup (~200ms savings).

_gaudi_nvm_load() {
	# Remove the stub functions first to avoid recursion
	unset -f nvm node npm npx yarn pnpm corepack 2> /dev/null

	# Find and source the real nvm.sh
	local nvm_sh=""
	if [[ -s "$NVM_DIR/nvm.sh" ]]; then
		nvm_sh="$NVM_DIR/nvm.sh"
	elif [[ -n "${GAUDI_HOST_HOMEBREW_PREFIX:-}" ]] && [[ -s "$GAUDI_HOST_HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]]; then
		nvm_sh="$GAUDI_HOST_HOMEBREW_PREFIX/opt/nvm/nvm.sh"
	fi

	if [[ -n "$nvm_sh" ]]; then
			source "$nvm_sh"
			# Load nvm bash completion if available
			# shellcheck source=/dev/null
			[[ -s "${nvm_sh%/*}/bash_completion" ]] && source "${nvm_sh%/*}/bash_completion"
	else
		echo "${GAUDI_HOST_NAME:-gaudi}: nvm not found. Install from https://github.com/nvm-sh/nvm"
		return 1
	fi
}

# Create stub functions for common Node commands that trigger lazy loading.
# Only when nvm is installed: without it the stubs would shadow the system
# node, npm, ... and fail with "nvm not found" instead of running them.
_gaudi_nvm_found=""
for _gaudi_nvm_dir in "$NVM_DIR" "${GAUDI_HOST_HOMEBREW_PREFIX:+${GAUDI_HOST_HOMEBREW_PREFIX}/opt/nvm}" "${HOMEBREW_PREFIX:+${HOMEBREW_PREFIX}/opt/nvm}" /opt/homebrew/opt/nvm /usr/local/opt/nvm; do
	if [[ -n "$_gaudi_nvm_dir" && -s "${_gaudi_nvm_dir}/nvm.sh" ]]; then
		_gaudi_nvm_found=1
		break
	fi
done

if [[ -n "$_gaudi_nvm_found" ]]; then
	nvm() { _gaudi_nvm_load && nvm "$@"; }
	node() { _gaudi_nvm_load && node "$@"; }
	npm() { _gaudi_nvm_load && npm "$@"; }
	npx() { _gaudi_nvm_load && npx "$@"; }
	yarn() { _gaudi_nvm_load && yarn "$@"; }
	pnpm() { _gaudi_nvm_load && pnpm "$@"; }
	corepack() { _gaudi_nvm_load && corepack "$@"; }
fi
unset _gaudi_nvm_found _gaudi_nvm_dir
