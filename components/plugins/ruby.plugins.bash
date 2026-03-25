# shellcheck shell=bash

cite about-plugin
about-plugin 'Ruby and rubygems specific functions and settings'

# Make commands installed with 'gem install --user-install' available
# ~/.gem/ruby/${RUBY_VERSION}/bin/
if which ruby >/dev/null && which gem >/dev/null; then
  pathmunge "$(ruby -e 'print Gem.user_dir')/bin" after
fi

remove_gem () {
  about 'Removes installed gem'
  group 'Ruby'

  gem list | grep $1 | awk '{ print $1; }' | xargs sudo gem uninstall
}
