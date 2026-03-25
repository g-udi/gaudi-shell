# shellcheck shell=bash

cite about-plugin
about-plugin 'Create Simple HTTP Server'

if [[ "$(uname)" = "Linux" ]]
then
  alias https='python2 -m SimpleHTTPServer'
else
  alias https='python -m SimpleHTTPServer'
fi