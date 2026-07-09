#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME=""
CONTAINER_NAME="tmp"
TMP="false"
PROXY_URL=""
SYS_ADMIN="false"
TIME_ZONE=""
ROOT_MODE="false"
GPU_ARGS=()

print_help() {
    cat <<'EOF'
Usage: ./scripts/run.sh [options]

Run a container from an existing image.

By default the container runs as the invoking host user (same UID/GID and group),
with /etc/passwd and /etc/group mounted read-only so names, home, and groups
resolve. Your host home is mounted at /home, so ~/.ssh and dotfiles are already
present. Use --root to run as root instead (legacy behavior).

Options:
  -i, --image-name <name>        Docker image to run. Required.
  -c, --container-name <name>    Container name. Defaults to tmp.
  --tmp                          Run interactively and remove the container on exit.
  --root                         Run as root instead of the host user.
  --proxy <url>                  Set http_proxy, https_proxy, and all_proxy.
  --sys-admin                    Add SYS_ADMIN capability and disable seccomp and apparmor.
  --gpus <value>                 Override GPU request, for example: all.
  --time-zone <tz>               Pass TZ into the container, for example: America/Los_Angeles, Asia/Shanghai.
  -h, --help                     Show this help message and exit.

Notes:
  GPU access is enabled automatically for image names containing "cuda".
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--image-name)
            if [[ $# -lt 2 ]]; then
                echo "[run.sh] ERROR: Missing value for $1." >&2
                exit 1
            fi
            IMAGE_NAME="$2"
            shift 2
            ;;
        -c|--container-name)
            if [[ $# -lt 2 ]]; then
                echo "[run.sh] ERROR: Missing value for $1." >&2
                exit 1
            fi
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --tmp)
            TMP="true"
            shift
            ;;
        --proxy)
            if [[ $# -lt 2 ]]; then
                echo "[run.sh] ERROR: Missing value for --proxy." >&2
                exit 1
            fi
            PROXY_URL="$2"
            shift 2
            ;;
        --sys-admin)
            SYS_ADMIN="true"
            shift
            ;;
        --root)
            ROOT_MODE="true"
            shift
            ;;
        --gpus)
            if [[ $# -lt 2 ]]; then
                echo "[run.sh] ERROR: Missing value for --gpus." >&2
                exit 1
            fi
            GPU_ARGS=(--gpus "$2")
            shift 2
            ;;
        --time-zone)
            if [[ $# -lt 2 ]]; then
                echo "[run.sh] ERROR: Missing value for --time-zone." >&2
                exit 1
            fi
            TIME_ZONE="$2"
            shift 2
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "[run.sh] ERROR: Unknown argument: $1" >&2
            print_help >&2
            exit 1
            ;;
    esac
done

if [[ -z "${IMAGE_NAME}" ]]; then
    echo "[run.sh] ERROR: Image name is required. Use -i or --image-name to specify it." >&2
    exit 1
fi

if [[ -n "${PROXY_URL}" ]]; then
    PROXY_ARGS=(
        -e "http_proxy=${PROXY_URL}"
        -e "https_proxy=${PROXY_URL}"
        -e "all_proxy=${PROXY_URL}"
    )
else
    PROXY_ARGS=()
fi

if [[ "${SYS_ADMIN}" == "true" ]]; then
    SYS_ADMIN_ARGS=(
        "--cap-add" "SYS_ADMIN"
        "--security-opt" "seccomp=unconfined"
        "--security-opt" "apparmor=unconfined"
    )
else
    SYS_ADMIN_ARGS=()
fi

if [[ ${#GPU_ARGS[@]} -eq 0 ]] && [[ "${IMAGE_NAME}" == *"cuda"* ]]; then
    GPU_ARGS=(--gpus all)
fi

if [[ -n "${TIME_ZONE}" ]]; then
    TZ_ARGS=(-e "TZ=${TIME_ZONE}")
else
    TZ_ARGS=()
fi

if [[ "${ROOT_MODE}" == "true" ]]; then
    USER_ARGS=()
else
    # Run as the host user: mount the host user/group databases read-only so
    # names, home, and groups resolve, and pass HOME/USER explicitly so even
    # non-login shells (docker exec) land in the right home.
    USER_ARGS=(
        -u "$(id -u):$(id -g)"
        -v /etc/passwd:/etc/passwd:ro
        -v /etc/group:/etc/group:ro
        -e "HOME=${HOME}"
        -e "USER=$(id -un)"
    )
fi

DOCKER_RUN_ARGS=(
    --name "${CONTAINER_NAME}"
    --network host
    --shm-size 20G
    --hostname "${CONTAINER_NAME}"
    -v /home:/home
)

DOCKER_RUN_ARGS+=(
    "${USER_ARGS[@]}"
    "${PROXY_ARGS[@]}"
    "${SYS_ADMIN_ARGS[@]}"
    "${GPU_ARGS[@]}"
    "${TZ_ARGS[@]}"
)

if [[ "${TMP}" == "true" ]]; then
    docker run -it --rm "${DOCKER_RUN_ARGS[@]}" "${IMAGE_NAME}" /bin/bash
else
    docker run -td "${DOCKER_RUN_ARGS[@]}" "${IMAGE_NAME}"
    # In root mode the host home is not the container home, so copy ~/.ssh into
    # /root. In host-user mode the mounted home already contains ~/.ssh.
    if [[ "${ROOT_MODE}" == "true" ]] && [[ -d "${HOME}/.ssh" ]]; then
        docker cp "${HOME}/.ssh" "${CONTAINER_NAME}:/root/"
        docker exec "${CONTAINER_NAME}" chown -R root:root /root/.ssh
    fi
fi
