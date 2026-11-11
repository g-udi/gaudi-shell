# shellcheck shell=bash
# shellcheck disable=SC1090

cite about-plugin
about-plugin 'Python version management via pyenv (lazy-loaded for fast startup)'

export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

# Nothing to do without pyenv: the stubs below would shadow the system python
# and pip and fail with "pyenv not found" instead of running them
[[ -x "$PYENV_ROOT/bin/pyenv" ]] || hash pyenv 2> /dev/null || return 0

pathmunge "$PYENV_ROOT/bin"

# Add shims to PATH immediately so the correct python/pip is found,
# but defer the expensive pyenv init (rehash + shell function setup).
pathmunge "$PYENV_ROOT/shims"

_gaudi_pyenv_load() {
	# Remove stubs to avoid recursion
	unset -f pyenv python python3 pip pip3 2> /dev/null

	if type -P pyenv &> /dev/null; then
		eval "$(pyenv init - bash --no-rehash)"

		# Load pyenv virtualenv if available
		if pyenv virtualenv-init - &> /dev/null; then
			eval "$(pyenv virtualenv-init - bash)"
		fi
	else
		echo "${GAUDI_HOST_NAME:-gaudi}: pyenv not found"
		return 1
	fi
}

# Create stub functions that trigger lazy loading
pyenv() { _gaudi_pyenv_load && pyenv "$@"; }
python() { _gaudi_pyenv_load && python "$@"; }
python3() { _gaudi_pyenv_load && python3 "$@"; }
pip() { _gaudi_pyenv_load && pip "$@"; }
pip3() { _gaudi_pyenv_load && pip3 "$@"; }
