#!/usr/bin/env sh
# shellcheck shell=sh
#
# gaudi-shell CLI dispatcher
#
# Main command: gaudi <verb> [args...]
# Alias: g <verb> [args...]

gaudi() {
    local verb="${1:-help}"
    shift 2>/dev/null || true

    case "$verb" in
        enable)   gaudi_enable "$@" ;;
        disable)  gaudi_disable "$@" ;;
        show)     gaudi_show "$@" ;;
        search)   gaudi_search "$@" ;;
        profile)  gaudi_profile_dispatch "$@" ;;
        reload)   gaudi_reload ;;
        version)  gaudi_version ;;
        help | *) gaudi_help ;;
    esac
}

gaudi_show() {
    local type="${1:-}"
    local mode="${2:-all}"

    if [ -z "$type" ]; then
        # Show all enabled
        for t in aliases plugins completions; do
            local items
            items="$(gaudi_list "$t" "enabled")"
            [ -n "$items" ] && printf "  %s: %s\n" "$t" "$(echo "$items" | tr '\n' ' ')"
        done
    else
        gaudi_list "$(gaudi_pluralize "$type")" "$mode"
    fi
}

gaudi_profile_dispatch() {
    local action="${1:-}"
    shift 2>/dev/null || true

    case "$action" in
        save) gaudi_profile_save "$@" ;;
        load) gaudi_profile_load "$@" ;;
        list) gaudi_profile_list ;;
        rm)   gaudi_profile_rm "$@" ;;
        *)    echo "usage: gaudi profile [save|load|list|rm] [name]" ;;
    esac
}

gaudi_reload() {
    local shell
    shell="$(gaudi_detect_shell)"

    case "$shell" in
        bash) exec bash --login ;;
        zsh)  exec zsh --login ;;
        fish) exec fish --login ;;
        *)    echo "reload: unsupported shell '$shell'" >&2; return 1 ;;
    esac
}

gaudi_version() {
    local root
    root="$(gaudi_root)"

    echo "gaudi-shell"
    echo "  shell: $(gaudi_detect_shell)"
    echo "  root:  $root"

    if [ -d "$root/.git" ]; then
        local tag sha
        tag="$(cd "$root" && git describe --tags --abbrev=0 2>/dev/null)"
        sha="$(cd "$root" && git log --pretty=format:'%h' -n 1 2>/dev/null)"
        [ -n "$tag" ] && echo "  version: $tag"
        [ -n "$sha" ] && echo "  commit:  $sha"
    fi
}

gaudi_help() {
    cat <<'EOF'
gaudi-shell — cross-shell framework for aliases, plugins, completions, and themes

Usage: gaudi <command> [arguments]

Commands:
  show [type]              List components (aliases, plugins, completions)
  show [type] enabled      List only enabled components
  enable <type> <name>     Enable a component
  disable <type> <name>    Disable a component
  search <term>            Search for components by keyword
  profile save <name>      Save enabled components as a named profile
  profile load <name>      Load a saved profile
  profile list             List saved profiles
  profile rm <name>        Remove a saved profile
  reload                   Restart the shell with a fresh session
  version                  Show gaudi-shell version info
  help                     Show this help message

Aliases: 'g' is a shortcut for 'gaudi'
EOF
}

# Short alias
alias g='gaudi'
