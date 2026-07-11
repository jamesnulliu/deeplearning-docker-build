#!/usr/bin/env bash

set -euo pipefail

# Writing /etc/localtime and /etc/timezone needs root. When the container runs as
# the host user, skip it -- libc already honors the TZ environment variable.
if [ "$(id -u)" -eq 0 ] && [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
  ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  echo "${TZ}" > /etc/timezone
fi

if [ "$(id -u)" -ne 0 ]; then
  mkdir -p "${HOME}"
  # bash needs at least ~/.bashrc to have any hook into a fresh, empty
  # workspace home -- this is the one thing entrypoint seeds automatically.
  # Everything else (env_setup.sh, .inputrc, .tmux.conf, .ssh/.gitconfig) is
  # an explicit, user-invoked function -- see the seeded ~/.bashrc's banner.
  if [ -n "${CONTAINER_DEFAULT_BASHRC:-}" ] && [ -r "${CONTAINER_DEFAULT_BASHRC}" ] \
      && [ ! -e "${HOME}/.bashrc" ]; then
    cp "${CONTAINER_DEFAULT_BASHRC}" "${HOME}/.bashrc"
  fi
fi

if [[ $# -eq 0 ]]; then
  exec "/bin/bash"
else
  exec "$@"
fi
