# shellcheck shell=bash

cite about-plugin
about-plugin 'SSH Agent helper functions'

_get_sshagent_pid_from_env_file () {
  local env_file="${1}"
  [[ -r "${env_file}" ]] || {
    echo "";
    return
  }
  tail -1 "${env_file}" \
  | cut -d' ' -f4 \
  | cut -d';' -f1
}

_is_item_in_list () {
  local item
  for item in "${@:2}"; do
    if [[ "${item}" == "${1}" ]]; then
      return 0
    fi
  done
  return 1
}


_is_proc_alive_at_pid () {
  local \
    pid \
    expected_name \
    actual_name \
    actual_state
  pid="${1?}"
  expected_name="ssh-agent"
  # kill -0 and ps work on both Linux and macOS (there is no /proc on macOS)
  kill -0 "${pid}" 2> /dev/null || return 1
  # the pid may have been reused: make sure it still is an ssh-agent
  actual_name=$(ps -p "${pid}" -o comm= 2> /dev/null)
  actual_name="${actual_name##*/}"
  [[ "${actual_name%% *}" == "${expected_name}" ]] || return 1
  # we want to exclude: X (killed), T (traced), Z (zombie)
  actual_state=$(ps -p "${pid}" -o stat= 2> /dev/null)
  if _is_item_in_list "${actual_state:0:1}" "X" "T" "Z"; then
    return 1
  fi
  return 0
}


_ensure_valid_sshagent_env () {
  local \
    agent_pid \
    tmp_res

  mkdir -p "${HOME}/.ssh"
  type restorecon &> /dev/null
  tmp_res="$?"

  if [[ "${tmp_res}" -eq 0 ]]; then
    restorecon -rv "${HOME}/.ssh"
  fi

  # no env file -> shoot a new agent
  if ! [[ -r "${SSH_AGENT_ENV}" ]]; then
    ssh-agent > "${SSH_AGENT_ENV}"
    return
  fi

  ## do not trust pre-existing SSH_AGENT_ENV
  agent_pid=$(_get_sshagent_pid_from_env_file "${SSH_AGENT_ENV}")
  if [[ -z "${agent_pid}" ]]; then
    # no pid detected -> shoot a new agent
    ssh-agent > "${SSH_AGENT_ENV}"
    return
  fi

  ## do not trust SSH_AGENT_PID
  if _is_proc_alive_at_pid "${agent_pid}"; then
    return
  fi

  ssh-agent > "${SSH_AGENT_ENV}"
  return
}


_ensure_sshagent_dead () {
  [[ -r "${SSH_AGENT_ENV}" ]] \
  || return ## no agent file - no problems
  ## ensure the file indeed points to a really running agent:
  agent_pid=$(
    _get_sshagent_pid_from_env_file \
    "${SSH_AGENT_ENV}"
  )

  [[ -n "${agent_pid}" ]] \
  || return # no pid - no problem

  _is_proc_alive_at_pid "${agent_pid}" \
  || return # process is not alive - no problem

  echo -e -n "Killing ssh-agent (pid:${agent_pid}) ... "
  kill -9 "${agent_pid}" && echo "DONE" || echo "FAILED"
  rm -f "${SSH_AGENT_ENV}"
}


sshagent () {
  about 'ensures ssh-agent is up and running'
  param '1: on|off '
  example '$ sshagent on'
  group 'sshagent'
  [[ -z "${SSH_AGENT_ENV}" ]] \
  && export SSH_AGENT_ENV="${HOME}/.ssh/agent_env.${HOSTNAME:-$(hostname)}"

  case "${1}" in
    on)
      command -v ssh-agent > /dev/null 2>&1 || return
      _ensure_valid_sshagent_env;
      # shellcheck disable=SC1090
      source "${SSH_AGENT_ENV}" > /dev/null;
      ;;
    off) _ensure_sshagent_dead
      ;;
    *)
      ;;
  esac
}

if [[ $- == *i* ]]; then
  sshagent on
fi
