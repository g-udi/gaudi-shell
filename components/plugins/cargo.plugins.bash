# shellcheck shell=bash

cite about-plugin
about-plugin 'Configure Cargo install directory and add Cargo binaries to PATH'

export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
pathmunge "$CARGO_HOME/bin" after
