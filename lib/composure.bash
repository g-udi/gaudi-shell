#!/usr/bin/env bash
# shellcheck shell=bash
#
# Composure compatibility stubs
# gaudi-shell doesn't use the full composure library but many ported
# components call these metadata functions. These stubs make them no-ops.

cite() { true; }
about() { true; }
about-alias() { true; }
about-plugin() { true; }
about-completion() { true; }
param() { true; }
example() { true; }
group() { true; }
priority() { true; }
