# shellcheck shell=bash

cite about-plugin
about-plugin 'Node.js helper functions'

# Ensure global modules are in PATH when a custom npm prefix is configured.
# The default prefix is where npm itself lives (already in PATH), so the
# override is read from the environment or the user's npmrc rather than
# running `npm config get prefix` at every shell start.
# If using nodenv, its shims already cover global modules.
if [[ "$PATH" != *"nodenv/shims"* ]]; then
  _node_npm_prefix="${NPM_CONFIG_PREFIX:-${npm_config_prefix:-}}"
  _node_npmrc="${NPM_CONFIG_USERCONFIG:-$HOME/.npmrc}"
  if [[ -z "$_node_npm_prefix" && -r "$_node_npmrc" ]]; then
    while IFS='=' read -r _node_key _node_value; do
      if [[ "${_node_key//[[:space:]]/}" == "prefix" ]]; then
        _node_npm_prefix="${_node_value//[[:space:]\"\']/}"
      fi
    done < "$_node_npmrc"
    # npmrc values may use ~ or ${HOME}
    _node_npm_prefix="${_node_npm_prefix/#\~/$HOME}"
    _node_npm_prefix="${_node_npm_prefix//\$\{HOME\}/$HOME}"
  fi
  if [[ -n "$_node_npm_prefix" ]]; then
    pathmunge "${_node_npm_prefix}/bin" "after"
  fi
  unset _node_npm_prefix _node_npmrc _node_key _node_value
fi
