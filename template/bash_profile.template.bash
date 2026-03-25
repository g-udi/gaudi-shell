#!/usr/bin/env bash

# Path to the gaudi-shell configuration
export GAUDI_SHELL="{{GAUDI_SHELL}}"

# Lock and Load a custom theme file
# Location /.gaudi-shell/themes/
export GAUDI_SHELL_THEME="gaudi"

# Don't check mail when opening terminal.
unset MAILCHECK

# Set this to false to turn off version control status checking within the prompt for all themes
export SCM_CHECK=true

# (Advanced): Uncomment this to make gaudi-shell reload itself automatically
# After enabling or disabling aliases, plugins, and completions.
export GAUDI_SHELL_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE=1

# Uncomment this to show gaudi-shell debug logs
# export GAUDI_SHELL_LOG_LEVEL=3

# Load gaudi-shell
source $GAUDI_SHELL/adapters/bash/init.bash
