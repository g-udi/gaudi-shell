# shellcheck shell=bash

cite about-plugin
about-plugin 'Manage your nginx service'

export NGINX_PATH='/opt/nginx'
pathmunge "$NGINX_PATH/sbin" after

# Print the pid from the nginx pid file, or fail when it is missing or not a number
_nginx_pid () {
  local pid_file="${NGINX_PATH}/logs/nginx.pid" pid
  if [[ ! -e "$pid_file" ]]; then
    echo "Nginx pid file not found" >&2
    return 1
  fi
  pid=$(< "$pid_file")
  if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
    echo "Nginx pid file does not hold a pid" >&2
    return 1
  fi
  echo "$pid"
}

# Show the sudo command and ask before running it
_nginx_sudo () {
  _read_input "Run 'sudo $*'? [y/n]"
  [[ "$REPLY" == [yY] ]] || return 1
  sudo "$@"
}

nginx_reload () {
  about 'Reload your nginx config'
  group 'nginx'

  local pid
  pid=$(_nginx_pid) || return 0
  echo "Reloading NGINX..."
  _nginx_sudo kill -HUP "$pid"
}

nginx_stop () {
  about 'Stop nginx'
  group 'nginx'

  local pid
  pid=$(_nginx_pid) || return 0
  echo "Stopping NGINX..."
  _nginx_sudo kill -INT "$pid"
}

nginx_start () {
  about 'Start nginx'
  group 'nginx'

  if [[ -e "${NGINX_PATH}/sbin/nginx" ]]; then
    echo "Starting NGINX..."
    _nginx_sudo "${NGINX_PATH}/sbin/nginx"
  else
    echo "Couldn't start nginx"
  fi
}

nginx_restart () {
  about 'Restart nginx'
  group 'nginx'

  local pid
  pid=$(_nginx_pid) || return 0
  echo "Stopping NGINX..."
  _nginx_sudo kill -INT "$pid" || return 1
  sleep 1
  echo "Starting NGINX..."
  _nginx_sudo "${NGINX_PATH}/sbin/nginx"
}
