#!/usr/bin/env bash
# shellcheck shell=bash

# History configuration — works in both bash and zsh

shopt -s histappend 2>/dev/null || true  # bash
setopt APPEND_HISTORY 2>/dev/null || true  # zsh (no-op in bash)

HISTCONTROL=ignoredups:ignorespace
HISTSIZE=10000
HISTFILESIZE=20000
