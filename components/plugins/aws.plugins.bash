# shellcheck shell=bash

cite about-plugin
about-plugin 'AWS helper functions'

AWS_CONFIG_FILE="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
AWS_SHARED_CREDENTIALS_FILE="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"

awskeys () {
    about 'Helper function for AWS credentials file'
    group 'AWS'

    if [[ ! -f "${AWS_SHARED_CREDENTIALS_FILE}" ]]; then
        echo "AWS credentials file not found"
        return 1
    fi

    if [[ $# -eq 1 ]] && [[ "$1" = "list" ]]; then
        __awskeys_list "$2"
    elif [[ $# -eq 1 ]] && [[ "$1" = "unset" ]]; then
        __awskeys_unset "$2"
    elif [[ $# -eq 2 ]] && [[ "$1" = "show" ]]; then
        __awskeys_show "$2"
    elif [[ $# -eq 2 ]] && [[ "$1" = "export" ]]; then
        __awskeys_export "$2"
    else
        __awskeys_help
    fi
}

__awskeys_help () {
    echo -e "Usage: awskeys [COMMAND] [profile]\n"
    echo -e "Helper to AWS credentials file.\n"
    echo -e "Commands:\n"
    echo "   help    Show this help message"
    echo "   list    List available AWS credentials profiles"
    echo "   show    Show the AWS keys associated to a credentials profile"
    echo "   export  Export an AWS credentials profile keys as environment variables"
    echo "   unset   Unset the AWS keys variables from the environment"
}

__awskeys_get () {
    local profile="$1"

    awk -v wanted="$profile" '
        /^\[[^]]+\]$/ {
            section = $0
            gsub(/^\[[[:space:]]*|[[:space:]]*\]$/, "", section)
            in_section = (section == wanted)
            next
        }
        in_section && /^[[:space:]]*(aws_access_key_id|aws_secret_access_key|aws_session_token)[[:space:]]*=/ {
            print
        }
    ' "${AWS_SHARED_CREDENTIALS_FILE}"
}

__awskeys_profiles () {
    {
        if [[ -f "${AWS_SHARED_CREDENTIALS_FILE}" ]]; then
            sed -nE 's/^\[[[:space:]]*([^]]+)[[:space:]]*\]$/\1/p' "${AWS_SHARED_CREDENTIALS_FILE}"
        fi
        if [[ -f "${AWS_CONFIG_FILE}" ]]; then
            sed -nE 's/^\[[[:space:]]*profile[[:space:]]+([^]]+)[[:space:]]*\]$/\1/p' "${AWS_CONFIG_FILE}"
        fi
    } | sort -u
}

__awskeys_profile_exists () {
    local profile

    while IFS= read -r profile; do
        [[ "$profile" == "$1" ]] && return 0
    done < <(__awskeys_profiles)

    return 1
}

__awskeys_list () {
    local credentials_list

    credentials_list="$(__awskeys_profiles)"
    if [[ -n "${credentials_list}" ]]; then
        echo -e "Available credentials profiles:\n"
        while IFS= read -r profile; do
            echo "    ${profile}"
        done <<< "${credentials_list}"
        echo
    else
        echo "No profiles found in credentials file"
    fi
}

__awskeys_show () {
    local p_keys

    p_keys="$(__awskeys_get "$1")"
    if [[ -n "${p_keys}" ]]; then
        echo "${p_keys}"
    else
        echo "Profile $1 not found in credentials file"
    fi
}

__awskeys_export () {
    if __awskeys_profile_exists "$1"; then
        local key value
        while IFS='=' read -r key value; do
            key="${key//[[:space:]]/}"
            value="${value#"${value%%[![:space:]]*}"}"
            [[ -n "$key" && -n "$value" ]] || continue
            export "$(echo "${key}" | tr "[:lower:]" "[:upper:]")=$value"
        done < <(__awskeys_get "$1")
        export AWS_PROFILE="$1"
    else
        echo "Profile $1 not found in credentials file"
    fi
}

__awskeys_unset () {
    unset AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

__awskeys_comp () {
    local cur prev opts

    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts="help list show export unset"

    case "${prev}" in
        help|list|unset)
            return 0
            ;;
        show|export)
            local profile_list

            profile_list="$(__awskeys_profiles)"
            # No mapfile: this file also loads in bash 3.2
            # shellcheck disable=SC2207
            COMPREPLY=($(compgen -W "${profile_list}" -- "${cur}"))
            return 0
            ;;
    esac

    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))

    return 0
}

complete -F __awskeys_comp awskeys
