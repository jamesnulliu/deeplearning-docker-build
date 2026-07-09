#!/usr/bin/env bash

IMAGE_VERSION=2.6.0
CUDA_VERSION=12.8.0
UBUNTU_VERSION=24.04
LLVM_VERSION=20
IMAGE_TAG="v${IMAGE_VERSION}"
IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-jamesnulliu/deeplearning}"

print_help() {
    cat <<'EOF'
Usage: source ./scripts/image-configs.sh
       ./scripts/image-configs.sh [--dockerfile <path>]

Options:
  --dockerfile <path>   Print the resolved image name for a dockerfile.
  -h, --help            Show this help message and exit.
EOF
}

resolve_image_tag() {
    local docker_file="${1:-}"

    case "${docker_file}" in
        *.cpu)
            printf '%s\n' "${IMAGE_TAG}-cpu"
            ;;
        *.cuda)
            printf '%s\n' "${IMAGE_TAG}-cuda${CUDA_VERSION}"
            ;;
        "")
            printf '%s\n' "${IMAGE_TAG}"
            ;;
        *)
            printf 'Unsupported dockerfile: %s\n' "${docker_file}" >&2
            return 1
            ;;
    esac
}

resolve_image_name() {
    local docker_file="${1:-}"
    local resolved_tag

    resolved_tag="$(resolve_image_tag "${docker_file}")"
    printf '%s:%s\n' "${IMAGE_REPOSITORY}" "${resolved_tag}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    docker_file=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dockerfile)
                if [[ $# -lt 2 ]]; then
                    echo "[image-configs.sh] ERROR: Missing value for --dockerfile." >&2
                    exit 1
                fi
                docker_file="$2"
                shift 2
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                echo "[image-configs.sh] ERROR: Unknown argument: $1" >&2
                print_help >&2
                exit 1
                ;;
        esac
    done

    if [[ -n "${docker_file}" ]]; then
        resolve_image_name "${docker_file}"
    else
        cat <<EOF
IMAGE_VERSION=2.6.0
CUDA_VERSION=${CUDA_VERSION}
UBUNTU_VERSION=${UBUNTU_VERSION}
LLVM_VERSION=${LLVM_VERSION}
IMAGE_TAG=${IMAGE_TAG}
IMAGE_REPOSITORY=${IMAGE_REPOSITORY}
EOF
    fi
fi
