#!/usr/bin/env bash

set -euo pipefail

# Writing /etc/localtime and /etc/timezone needs root. When the container runs as
# the host user, skip it -- libc already honors the TZ environment variable.
if [ "$(id -u)" -eq 0 ] && [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
  ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  echo "${TZ}" > /etc/timezone
fi

# In host-user mode, $HOME points at a per-user workspace directory (set by
# run.sh via -e HOME=..., pre-created host-side with correct ownership). Seed
# it once, idempotently, from the image's baked-in defaults and the real host
# home's ssh/git identity -- never overwriting anything already there, so
# accumulated state survives container recreation.
if [ "$(id -u)" -ne 0 ]; then
  mkdir -p "${HOME}"

  for pair in \
      "${CONTAINER_DEFAULT_BASHRC:-}=${HOME}/.bashrc" \
      "${CONTAINER_DEFAULT_BASH_PROFILE:-}=${HOME}/.bash_profile" \
      "${CONTAINER_DEFAULT_INPUTRC:-}=${HOME}/.inputrc" \
      "${CONTAINER_DEFAULT_TMUX_CONF:-}=${HOME}/.tmux.conf"; do
    src="${pair%%=*}"
    dst="${pair##*=}"
    [ -n "${src}" ] && [ -r "${src}" ] || continue
    [ -e "${dst}" ] && continue
    cp "${src}" "${dst}"
  done

  # Reads the bind-mounted host /etc/passwd (independent of the HOME
  # override above) to find the real host home, so ssh/git identity still
  # resolve even though $HOME now points at the workspace.
  REAL_HOST_HOME="$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6)" || true
  if [ -n "${REAL_HOST_HOME:-}" ] && [ "${REAL_HOST_HOME}" != "${HOME}" ]; then
    if [ -d "${REAL_HOST_HOME}/.ssh" ] && [ ! -e "${HOME}/.ssh" ]; then
      ln -s "${REAL_HOST_HOME}/.ssh" "${HOME}/.ssh"
    fi
    if [ -f "${REAL_HOST_HOME}/.gitconfig" ] && [ ! -e "${HOME}/.gitconfig" ]; then
      ln -s "${REAL_HOST_HOME}/.gitconfig" "${HOME}/.gitconfig"
    fi
  fi
fi

if [[ $# -eq 0 ]]; then
  exec "/bin/bash"
else
  exec "$@"
fi
