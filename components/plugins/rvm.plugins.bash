# shellcheck shell=bash
# shellcheck disable=SC1090,SC2154

cite about-plugin
about-plugin 'Ruby Version Manager (RVM)'

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Check to make sure that RVM is actually loaded before adding the customizations to it
if [[ "$rvm_path" ]]
then
    # Load the auto-completion script if RVM was loaded.
    [[ -r $rvm_path/scripts/completion ]] && . $rvm_path/scripts/completion

    switch () {
      about 'Switches to a Ruby version and reports it'
      param '1: Ruby version'
      group 'rvm'

      rvm $1
      local v
      v=$(rvm_version)
      rvm wrapper $1 textmate
      echo "Switch to Ruby version: $v"
    }

    rvm_default () {
      about 'Sets the default Ruby version'
      param '1: Ruby version'
      group 'rvm'

      rvm --default $1
      rvm wrapper $1 textmate
    }

    rvm_version () {
      about 'Shows the active Ruby version'
      group 'rvm'

      ruby --version
    }

fi
