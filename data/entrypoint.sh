#!/usr/bin/env bash

set -euo pipefail

# Writing /etc/localtime and /etc/timezone needs root. When the container runs as
# the host user, skip it -- libc already honors the TZ environment variable.
if [ "$(id -u)" -eq 0 ] && [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
  ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  echo "${TZ}" > /etc/timezone
fi

if [[ $# -eq 0 ]]; then
  exec "/bin/bash"
else
  exec "$@"
fi
