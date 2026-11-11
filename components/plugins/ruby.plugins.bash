# shellcheck shell=bash

cite about-plugin
about-plugin 'Ruby and rubygems specific functions and settings'

# Make commands installed with 'gem install --user-install' available
# ~/.gem/ruby/${RUBY_VERSION}/bin/
if which ruby >/dev/null && which gem >/dev/null; then
  pathmunge "$(ruby -e 'print Gem.user_dir')/bin" after
fi

remove_gem () {
  about 'Removes an installed gem (exact name) with sudo, after confirmation'
  param '1: gem name'
  group 'ruby'

  if [[ -z "${1:-}" ]]; then
    echo "Usage: remove_gem <gem name>" >&2
    return 1
  fi
  if ! gem list --no-versions | grep -qFx -- "$1"; then
    echo "remove_gem: gem '$1' is not installed" >&2
    return 1
  fi

  _read_input "Run 'sudo gem uninstall $1'? [y/n]"
  [[ "$REPLY" == [yY] ]] || return 1
  sudo gem uninstall "$1"
}
