#!/usr/bin/env sh
# shellcheck shell=sh
#
# gaudi-shell profile management
#
# Save, load, list, and remove named component configurations.

gaudi_profile_dir() {
    echo "$(gaudi_root)/profiles"
}

# Save current enabled components as a named profile
# $1: profile name
gaudi_profile_save() {
    local name="$1"
    local profile_dir enabled_dir profile_file

    [ -z "$name" ] && echo "error: provide a profile name" >&2 && return 1

    profile_dir="$(gaudi_profile_dir)"
    enabled_dir="$(gaudi_enabled_dir)"
    profile_file="$profile_dir/${name}.profile"

    mkdir -p "$profile_dir"

    if [ -f "$profile_file" ]; then
        printf "Profile '%s' exists. Overwrite? [y/N] " "$name"
        read -r reply
        case "$reply" in
            [yY]) ;;
            *) echo "cancelled" && return 0 ;;
        esac
    fi

    : > "$profile_file"
    local count=0

    for link in "$enabled_dir"/*; do
        [ -e "$link" ] || continue
        local base type_name
        base="$(basename "$link")"
        # Strip priority: 250___git.plugins -> git.plugins
        type_name="${base#*"$GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR"}"
        # Split: git.plugins -> type=plugins, name=git
        local comp_name="${type_name%%.*}"
        local comp_type="${type_name#*.}"

        echo "$(gaudi_singularize "$comp_type") $comp_name" >> "$profile_file"
        count=$((count + 1))
    done

    echo "saved profile '${name}' (${count} components)"
}

# Load a named profile
# $1: profile name
gaudi_profile_load() {
    local name="$1"
    local profile_file

    [ -z "$name" ] && echo "error: provide a profile name" >&2 && return 1

    profile_file="$(gaudi_profile_dir)/${name}.profile"

    [ -f "$profile_file" ] || { echo "error: profile '${name}' not found" >&2; return 1; }

    # Validate first
    local line_num=0 errors=0
    while IFS= read -r line || [ -n "$line" ]; do
        line_num=$((line_num + 1))
        [ -z "$line" ] && continue
        case "$line" in
            alias\ * | plugin\ * | completion\ * | theme\ *) ;;
            *) echo "error: invalid entry at line ${line_num}: ${line}" >&2; errors=$((errors + 1)) ;;
        esac
    done < "$profile_file"

    [ "$errors" -gt 0 ] && echo "profile validation failed" >&2 && return 1

    # Disable all
    local enabled_dir
    enabled_dir="$(gaudi_enabled_dir)"
    rm -f "$enabled_dir"/* 2>/dev/null

    # Enable from profile
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        local type="${line%% *}" comp="${line#* }"
        gaudi_enable "$type" "$comp"
    done < "$profile_file"

    echo "loaded profile '${name}'"
}

# List available profiles
gaudi_profile_list() {
    local profile_dir
    profile_dir="$(gaudi_profile_dir)"

    [ -d "$profile_dir" ] || { echo "no profiles found"; return 0; }

    for profile in "$profile_dir"/*.profile; do
        [ -f "$profile" ] || continue
        local name count
        name="$(basename "$profile" .profile)"
        count="$(wc -l < "$profile" | tr -d ' ')"
        printf "  %s (%s components)\n" "$name" "$count"
    done
}

# Remove a profile
# $1: profile name
gaudi_profile_rm() {
    local name="$1"

    [ -z "$name" ] && echo "error: provide a profile name" >&2 && return 1
    [ "$name" = "default" ] && echo "error: cannot remove 'default' profile" >&2 && return 1

    local profile_file
    profile_file="$(gaudi_profile_dir)/${name}.profile"

    [ -f "$profile_file" ] || { echo "error: profile '${name}' not found" >&2; return 1; }

    rm "$profile_file"
    echo "removed profile '${name}'"
}
