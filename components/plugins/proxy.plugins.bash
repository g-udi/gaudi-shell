cite about-plugin
about-plugin 'Proxy Tools'

PROXY_DIVIDER=$(printf '%.0s-' {1..30}; echo)
# sed in-place flags: the framework's own, else the legacy bash-it ones, else by OS
if ((${#GAUDI_SHELL_SED_I_PARAMETERS[@]} > 0)); then
	_gaudi_proxy_sed_i=("${GAUDI_SHELL_SED_I_PARAMETERS[@]}")
elif ((${#BASH_IT_SED_I_PARAMETERS[@]} > 0)); then
	_gaudi_proxy_sed_i=("${BASH_IT_SED_I_PARAMETERS[@]}")
else
	case $OSTYPE in
		darwin*) _gaudi_proxy_sed_i=(-i "") ;;
		*) _gaudi_proxy_sed_i=(-i) ;;
	esac
fi

disable-proxy () {
	about 'Disables proxy settings for Bash, npm and SSH'
	group 'Proxy'

	unset http_proxy
	unset https_proxy
	unset HTTP_PROXY
	unset HTTPS_PROXY
	unset ALL_PROXY
	unset no_proxy
	unset NO_PROXY

	echo "Disabled proxy environment variables"

	npm-disable-proxy
	ssh-disable-proxy
	svn-disable-proxy
}

enable-proxy () {
	about 'Enables proxy settings for Bash, npm and SSH'
	group 'Proxy'

	export http_proxy=${GAUDI_SHELL_HTTP_PROXY:-${BASH_IT_HTTP_PROXY:-}}
	export https_proxy=${GAUDI_SHELL_HTTPS_PROXY:-${BASH_IT_HTTPS_PROXY:-}}
	export HTTP_PROXY=$http_proxy
	export HTTPS_PROXY=$https_proxy
	export ALL_PROXY=$http_proxy
	export no_proxy=${GAUDI_SHELL_NO_PROXY:-${BASH_IT_NO_PROXY:-}}
	export NO_PROXY=$no_proxy

	echo "Enabled proxy environment variables"

	npm-enable-proxy
	ssh-enable-proxy
	svn-enable-proxy
}

enable-proxy-alt () {
	about 'Enables alternate proxy settings for Bash, npm and SSH'
	group 'Proxy'

	export http_proxy=${GAUDI_SHELL_HTTP_PROXY_ALT:-${BASH_IT_HTTP_PROXY_ALT:-}}
	export https_proxy=${GAUDI_SHELL_HTTPS_PROXY_ALT:-${BASH_IT_HTTPS_PROXY_ALT:-}}
	export HTTP_PROXY=$http_proxy
	export HTTPS_PROXY=$https_proxy
	export ALL_PROXY=$http_proxy
	export no_proxy=${GAUDI_SHELL_NO_PROXY:-${BASH_IT_NO_PROXY:-}}
	export NO_PROXY=$no_proxy
	echo "Enabled alternate proxy environment variables"

	npm-enable-proxy $http_proxy $https_proxy
	ssh-enable-proxy
	svn-enable-proxy $http_proxy
}

show-proxy () {
	about 'Shows the proxy settings for Bash, Git, npm and SSH'
	group 'Proxy'

  printf "\n${GREEN}%s${NC}\n$PROXY_DIVIDER\n" "Environment Variables"
	env | grep -i "proxy" | grep -Ev "BASH_IT|GAUDI_SHELL"

	gaudi-show-proxy
	npm-show-proxy
	git-global-show-proxy
	svn-show-proxy
	ssh-show-proxy
}

proxy-help () {
	about 'Provides an overview of the gaudi-shell proxy configuration'
	group 'Proxy'

	cat << EOF
gaudi-shell provides support for enabling/disabling proxy settings for various shell tools.

The following backends are currently supported (in addition to the shell's environment variables): Git, SVN, npm, ssh

gaudi-shell uses the following variables to set the shell's proxy settings when you call 'enable-proxy'.
These variables are best defined in a custom script in gaudi-shell's custom script folder ('$GAUDI_SHELL/components/custom'),
e.g. '$GAUDI_SHELL/components/custom/proxy.env.bash'
* GAUDI_SHELL_HTTP_PROXY and GAUDI_SHELL_HTTPS_PROXY: Define the proxy URL to be used, e.g. 'http://localhost:1234'
* GAUDI_SHELL_HTTP_PROXY_ALT and GAUDI_SHELL_HTTPS_PROXY_ALT: The alternate proxy used by 'enable-proxy-alt'
* GAUDI_SHELL_NO_PROXY: A comma-separated list of proxy exclusions, e.g. '127.0.0.1,localhost'
The legacy BASH_IT_* names of these variables still work.

Run 'glossary proxy' to show the available proxy functions with a short description.
EOF

	show-proxy
}

gaudi-show-proxy () {
	about 'Shows the gaudi-shell proxy settings'
	group 'Proxy'

  printf "\n${GREEN}%s${NC}\n%s\n$PROXY_DIVIDER\n" "gaudi-shell Environment Variables" "(These variables will be used to set the proxy when you call 'enable-proxy')"
	env | grep -E "(BASH_IT|GAUDI_SHELL).*PROXY"
}

npm-show-proxy () {
	about 'Shows the npm proxy settings'
	group 'Proxy'

	if command -v npm &> /dev/null ; then
    printf "\n${GREEN}%s${NC}\n$PROXY_DIVIDER\n" "npm"
		echo "npm HTTP  proxy: $(npm config get proxy)"
		echo "npm HTTPS proxy: $(npm config get https-proxy)"
		echo "npm proxy exceptions: $(npm config get noproxy)"
	fi
}

npm-disable-proxy () {
	about 'Disables npm proxy settings'
	group 'Proxy'

	if command -v npm &> /dev/null ; then
		npm config delete proxy
		npm config delete https-proxy
		npm config delete noproxy
		echo "Disabled npm proxy settings"
	fi
}

npm-enable-proxy () {
	about 'Enables npm proxy settings'
	group 'Proxy'

	local my_http_proxy=${1:-${GAUDI_SHELL_HTTP_PROXY:-${BASH_IT_HTTP_PROXY:-}}}
	local my_https_proxy=${2:-${GAUDI_SHELL_HTTPS_PROXY:-${BASH_IT_HTTPS_PROXY:-}}}
	local my_no_proxy=${3:-${GAUDI_SHELL_NO_PROXY:-${BASH_IT_NO_PROXY:-}}}

	if command -v npm &> /dev/null ; then
		npm config set proxy $my_http_proxy
		npm config set https-proxy $my_https_proxy
		npm config set noproxy $my_no_proxy
		echo "Enabled npm proxy settings"
	fi
}

git-global-show-proxy () {
	about 'Shows global Git proxy settings'
	group 'Proxy'

	if command -v git &> /dev/null ; then
    printf "\n${GREEN}%s${NC}\n$PROXY_DIVIDER\n" "Git (Global Settings)"
		echo "Git (Global) HTTP  proxy: $(git config --global --get http.proxy)"
		echo "Git (Global) HTTPS proxy: $(git config --global --get https.proxy)"
	fi
}

git-global-disable-proxy () {
	about 'Disables global Git proxy settings'
	group 'Proxy'

	if command -v git &> /dev/null ; then
		git config --global --unset-all http.proxy
		git config --global --unset-all https.proxy
		echo "Disabled global Git proxy settings"
	fi
}

git-global-enable-proxy () {
	about 'Enables global Git proxy settings'
	group 'Proxy'

	if command -v git &> /dev/null ; then
		git-global-disable-proxy

		git config --global --add http.proxy ${GAUDI_SHELL_HTTP_PROXY:-${BASH_IT_HTTP_PROXY:-}}
		git config --global --add https.proxy ${GAUDI_SHELL_HTTPS_PROXY:-${BASH_IT_HTTPS_PROXY:-}}
		echo "Enabled global Git proxy settings"
	fi
}

git-show-proxy () {
	about 'Shows current Git project proxy settings'
	group 'Proxy'

	if command -v git &> /dev/null ; then
    printf "\n${GREEN}%s${NC}\n$PROXY_DIVIDER\n" "Git Project Proxy Settings"
		echo "Git HTTP  proxy: $(git config --get http.proxy)"
		echo "Git HTTPS proxy: $(git config --get https.proxy)"
	fi
}

git-disable-proxy () {
	about 'Disables current Git project proxy settings'
	group 'Proxy'

	if command -v git &> /dev/null ; then
		git config --unset-all http.proxy
		git config --unset-all https.proxy
		echo "Disabled Git project proxy settings"
	fi
}

git-enable-proxy () {
	about 'Enables current Git project proxy settings'
	group 'Proxy'

	if command -v git &> /dev/null ; then
		git-disable-proxy

		git config --add http.proxy ${GAUDI_SHELL_HTTP_PROXY:-${BASH_IT_HTTP_PROXY:-}}
		git config --add https.proxy ${GAUDI_SHELL_HTTPS_PROXY:-${BASH_IT_HTTPS_PROXY:-}}
		echo "Enabled Git project proxy settings"
	fi
}


svn-show-proxy () {
	about 'Shows SVN proxy settings'
	group 'Proxy'

	if command -v svn &> /dev/null && command -v python3 &> /dev/null ; then
    printf "\n${GREEN}%s${NC}\n$PROXY_DIVIDER\n" "SVN Proxy Settings"
		python3 - <<END
import configparser, os
config = configparser.RawConfigParser()
config.read(os.path.expanduser('~/.subversion/servers'))
if (config.has_section('global')):
	proxy_host = ''
	proxy_port = ''
	proxy_exceptions = ''
	if (config.has_option('global', 'http-proxy-host')):
		proxy_host = config.get('global', 'http-proxy-host')
	if (config.has_option('global', 'http-proxy-port')):
		proxy_port = config.get('global', 'http-proxy-port')
	if (config.has_option('global', 'http-proxy-exceptions')):
		proxy_exceptions = config.get('global', 'http-proxy-exceptions')
	print('http-proxy-host      : ' + proxy_host)
	print('http-proxy-port      : ' + proxy_port)
	print('http-proxy-exceptions: ' + proxy_exceptions)
END
	fi
}

svn-disable-proxy () {
	about 'Disables SVN proxy settings'
	group 'Proxy'

	if command -v svn &> /dev/null && command -v python3 &> /dev/null ; then
		python3 - <<END
import configparser, os
config = configparser.RawConfigParser()
config.read(os.path.expanduser('~/.subversion/servers'))
if config.has_section('global'):
	changed = False
	if config.has_option('global', 'http-proxy-host'):
		config.remove_option('global', 'http-proxy-host')
		changed = True
	if config.has_option('global', 'http-proxy-port'):
		config.remove_option('global', 'http-proxy-port')
		changed = True
	if config.has_option('global', 'http-proxy-exceptions'):
		config.remove_option('global', 'http-proxy-exceptions')
		changed = True
	if changed:
		with open(os.path.expanduser('~/.subversion/servers'), 'w') as configfile:
			config.write(configfile)
	print('Disabled SVN proxy settings')
END
	fi
}

svn-enable-proxy () {
	about 'Enables SVN proxy settings'
	group 'Proxy'

	if command -v svn &> /dev/null && command -v python3 &> /dev/null ; then
		local my_http_proxy=${1:-${GAUDI_SHELL_HTTP_PROXY:-${BASH_IT_HTTP_PROXY:-}}}

		python3 - "$my_http_proxy" "${GAUDI_SHELL_NO_PROXY:-${BASH_IT_NO_PROXY:-}}" <<END
import configparser, os, sys
from urllib.parse import urlparse
pieces = urlparse(sys.argv[1])
host = pieces.hostname
port = pieces.port
exceptions = sys.argv[2]
config = configparser.RawConfigParser()
config.read(os.path.expanduser('~/.subversion/servers'))
if not config.has_section('global'):
	config.add_section('global')
if host is not None:
	config.set('global', 'http-proxy-host', host)
else:
	config.remove_option('global', 'http-proxy-host')
if port is not None:
	config.set('global', 'http-proxy-port', str(port))
else:
	config.remove_option('global', 'http-proxy-port')
if exceptions:
	config.set('global', 'http-proxy-exceptions', exceptions)
else:
	config.remove_option('global', 'http-proxy-exceptions')
with open(os.path.expanduser('~/.subversion/servers'), 'w') as configfile:
	config.write(configfile)
print('Enabled SVN proxy settings')
END
	fi
}

ssh-show-proxy () {
	about 'Shows SSH config proxy settings (from ~/.ssh/config)'
	group 'Proxy'

	if [[ -f ~/.ssh/config ]] ; then
    printf "\n${GREEN}%s${NC}\n$PROXY_DIVIDER\n" "SSH Config Enabled in ~/.ssh/config"
		awk '
		    $1 == "Host" {
		        host = $2;
		        next;
		    }
		    $1 == "ProxyCommand" {
		        $1 = "";
		        printf "%s\t%s\n", host, $0
		    }
		' ~/.ssh/config | column -t

    printf "\n${GREEN}%s${NC}\n$PROXY_DIVIDER\n" "SSH Config Disabled in ~/.ssh/config"
		awk '
		    $1 == "Host" {
		        host = $2;
		        next;
		    }
		    $0 ~ "^#.*ProxyCommand.*" {
		        $1 = "";
		        $2 = "";
		        printf "%s\t%s\n", host, $0
		    }
		' ~/.ssh/config | column -t
	fi
}

ssh-disable-proxy () {
	about 'Disables SSH config proxy settings'
	group 'Proxy'

	if [[ -f ~/.ssh/config ]] ; then
		if grep -q '^[^#]*ProxyCommand' ~/.ssh/config; then
			sed -e's/^[^#]*ProxyCommand/#	ProxyCommand/' "${_gaudi_proxy_sed_i[@]}" ~/.ssh/config
			echo "Disabled SSH config proxy settings"
		else
			echo "No active SSH ProxyCommand to disable"
		fi
	fi
}


ssh-enable-proxy () {
	about 'Enables SSH config proxy settings'
	group 'Proxy'

	if [[ -f ~/.ssh/config ]] ; then
		if grep -q '^#	ProxyCommand' ~/.ssh/config; then
			sed -e's/#	ProxyCommand/	ProxyCommand/' "${_gaudi_proxy_sed_i[@]}" ~/.ssh/config
			echo "Enabled SSH config proxy settings"
		else
			echo "No disabled SSH ProxyCommand to enable"
		fi
	fi
}
