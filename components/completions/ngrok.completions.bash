# shellcheck shell=bash
# shellcheck disable=SC2155,SC2207

cite about-completion
about-completion 'Ngrok bash completions'

__ngrok_completion() {
	
	local prev=$(_get_pword)
	local curr=$(_get_cword)

	local BASE_NO_CONF="--log --log-format --log-level --help"
	local BASE="--config $BASE_NO_CONF"
	local DEFAULT="$BASE --authtoken --region"

	case $prev in
		authtoken)
			COMPREPLY=($(compgen -W "$BASE" -- "$curr"))
			;;
		http)
			COMPREPLY=($(compgen -W "$DEFAULT --auth --bind-tls --host-header --hostname --inspect --subdomain" -- "$curr"))
			;;
		start)
			COMPREPLY=($(compgen -W "$DEFAULT --all --none" -- "$curr"))
			;;
		tcp)
			COMPREPLY=($(compgen -W "$DEFAULT --remote-addr" -- "$curr"))
			;;
		tls)
			COMPREPLY=($(compgen -W "$DEFAULT --client-cas --crt --hostname --key --subdomain" -- "$curr"))
			;;
		update)
			COMPREPLY=($(compgen -W "$BASE_NO_CONF --channel" -- "$curr"))
			;;
		ngrok)
			COMPREPLY=($(compgen -W "authtoken credits http start tcp tls update version help" -- "$curr"))
			;;
		*) ;;

	esac
}

complete -F __ngrok_completion ngrok
