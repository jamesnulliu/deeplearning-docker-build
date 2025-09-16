#!/bin/bash

set -e


IMAGE_NAME=""
CONTAINER_NAME="tmp"
TMP="false"

function print_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help             Show this help message and exit"
    echo "  -i, --image-name       Name of the Docker image to use (required)"
    echo "  -c, --container-name   Name of the Docker container (default: tmp)"
    echo "  --tmp                  Create a temporary container and attach to it;"
    echo "                         The container would be removed after exit"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -I|--image-name)
            IMAGE_NAME="$2"; shift ;;
        -C|--container-name)
            CONTAINER_NAME="$2"; shift ;;
        --tmp)
            TMP="true" ;;
        -h|--help)
            print_help; exit 0 ;;
        *)
            echo "[build.sh] ERROR: Unknown argument: $1"
            print_help; exit 1 ;;
    esac
    shift
done


if [ -z "$IMAGE_NAME" ]; then
    echo "[run.sh] ERROR: Image name is required. Use -i or --image-name to specify it."
    exit 1
fi

if [ "$TMP" = "true" ]; then
    docker run -it --rm \
        --name $CONTAINER_NAME \
        --gpus all \
        --network host \
        --shm-size 20G \
        --hostname $CONTAINER_NAME \
        -v /home:/home \
        $IMAGE_NAME /bin/bash
else
    if [[ "$IMAGE_NAME" == *"cuda"* ]]; then
        docker run -td \
            --name $CONTAINER_NAME \
            --gpus all \
            --network host \
            --shm-size 20G \
            --hostname $CONTAINER_NAME \
            -v /home:/home \
            $IMAGE_NAME
    else
        docker run -td \
            --name $CONTAINER_NAME \
            --network host \
            --shm-size 20G \
            --hostname $CONTAINER_NAME \
            -v /home:/home \
            $IMAGE_NAME
    fi
    docker cp $HOME/.ssh $CONTAINER_NAME:/root/
    docker start $CONTAINER_NAME
    docker exec $CONTAINER_NAME chown -R root:root /root/.ssh
fi

