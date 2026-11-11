# shellcheck shell=bash

cite about-plugin
about-plugin 'Helper functions for using docker-compose'

docker-compose-fresh () {
  about 'Shut down, remove and start again the docker-compose setup, then tail the logs'
  group 'docker-compose'
  example 'docker-compose-fresh docker-compose-foo.yaml'

  local -a dco_file_param=()
  if [[ -n "$1" ]]; then
    echo "Using docker-compose file: $1"
    dco_file_param=(--file "$1")
  fi

  docker-compose "${dco_file_param[@]}" stop
  docker-compose "${dco_file_param[@]}" rm -f
  docker-compose "${dco_file_param[@]}" up -d
  docker-compose "${dco_file_param[@]}" logs -f --tail 100
}
