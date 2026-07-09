#!/usr/bin/env bash

set -euo pipefail

print_help() {
    cat <<'EOF'
Usage: ./scripts/exec.sh [container-name] [--root]

Open a shell in an existing container. Defaults to tmp.

By default the shell runs as the invoking host user (matching a container started
by run.sh without --root). Use --root to open a root shell for admin tasks.

Options:
  --root                Open the shell as root instead of the host user.
  -h, --help            Show this help message and exit.
EOF
}

CONTAINER_NAME="tmp"
ROOT_MODE="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            print_help
            exit 0
            ;;
        --root)
            ROOT_MODE="true"
            shift
            ;;
        -*)
            echo "[exec.sh] ERROR: Unknown option: $1" >&2
            print_help >&2
            exit 1
            ;;
        *)
            CONTAINER_NAME="$1"
            shift
            ;;
    esac
done

if [[ "${ROOT_MODE}" == "true" ]]; then
    USER_ARGS=(-u 0:0)
else
    USER_ARGS=(-u "$(id -u):$(id -g)")
fi

if [[ -z "$(docker ps -q -f "name=^${CONTAINER_NAME}$")" ]]; then
    docker start "${CONTAINER_NAME}"
fi

docker exec -it "${USER_ARGS[@]}" "${CONTAINER_NAME}" /bin/bash
