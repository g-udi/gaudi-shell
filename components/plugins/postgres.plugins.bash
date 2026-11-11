# shellcheck shell=bash

cite about-plugin
about-plugin 'Postgres helper functions'

if _command_exists pg_config; then

  PGVERSION=$(pg_config --version | awk '{print $2}')
  POSTGRES_BIN=$(pg_config --bindir)

  export PGVERSION
  export POSTGRES_BIN

  # Homebrew keeps the data directory under its prefix (var/postgres or var/postgresql@<version>)
  _gaudi_pg_brew="${GAUDI_HOST_HOMEBREW_PREFIX:-${HOMEBREW_PREFIX:-}}"
  if [[ -z "$_gaudi_pg_brew" ]]; then
    _gaudi_pg_brew=/usr/local
    [[ -d /opt/homebrew/var ]] && _gaudi_pg_brew=/opt/homebrew
  fi
  COMMON_PGDATA_PATHS=("${_gaudi_pg_brew}/var/postgres" "${_gaudi_pg_brew}/var/"postgresql@* "/var/pgsql" "/Library/Server/PostgreSQL/Data")
  unset _gaudi_pg_brew
  for possible in "${COMMON_PGDATA_PATHS[@]}"
  do
    :
    if [[ -f "$possible/pg_hba.conf" ]]
    then
        export PGDATA=$possible
    fi
  done

  postgres_start () {
    about 'Starts PostgreSQL server'
    group 'postgres'

    echo 'Starting PostgreSQL....';
    [[ -n "${PGDATA:-}" ]] || { echo "PGDATA is not set"; return 1; }
    "$POSTGRES_BIN"/pg_ctl -D "$PGDATA" -l "$PGDATA"/logfile start
  }

  postgres_stop () {
    about 'Stops PostgreSQL server'
    group 'postgres'

    echo 'Stopping PostgreSQL....';
    [[ -n "${PGDATA:-}" ]] || { echo "PGDATA is not set"; return 1; }
    "$POSTGRES_BIN"/pg_ctl -D "$PGDATA" -l "$PGDATA"/logfile stop -s -m fast
  }

  postgres_status () {
    about 'Returns status of PostgreSQL server'
    group 'postgres'

    # $POSTGRES_BIN/pg_ctl -D $PGDATA status
    if [[ $(is_postgres_running) == "no server running" ]]
    then
      echo "PostgreSQL service [STOPPED]"
    else
      echo "PostgreSQL service [RUNNING]"
    fi
  }


  is_postgres_running () {
    [[ -n "${PGDATA:-}" ]] || { echo "PGDATA is not set"; return 1; }
    "$POSTGRES_BIN"/pg_ctl -D "$PGDATA" status | grep -E -o "no server running"
  }


  postgres_restart () {
    about 'Restarts status of PostgreSQL server'
    group 'postgres'

    echo 'Restarting PostgreSQL....';
    [[ -n "${PGDATA:-}" ]] || { echo "PGDATA is not set"; return 1; }
    "$POSTGRES_BIN"/pg_ctl -D "$PGDATA" restart
  }

  postgres_logfile () {
    about 'View the last 500 lines from logfile'
    group 'postgres'

    [[ -n "${PGDATA:-}" ]] || { echo "PGDATA is not set"; return 1; }
    tail -500 "$PGDATA"/logfile | less
  }

  postgres_serverlog () {
    about 'View the last 500 lines from server.log'
    group 'postgres'

    [[ -n "${PGDATA:-}" ]] || { echo "PGDATA is not set"; return 1; }
    tail -500 "$PGDATA"/server.log | less
  }


fi
