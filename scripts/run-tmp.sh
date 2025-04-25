CONTAINER_NAME=$1

source ./scripts/.image-configs.sh

if [ ! $CONTAINER_NAME ]; then
    CONTAINER_NAME=tmp
fi

docker run --rm \
    -it \
    --name $CONTAINER_NAME \
    --gpus all \
    --network=host \
    --hostname $CONTAINER_NAME \
    -v $HOME/Projects:/root/Projects \
    $IMAGE_NAME \
    /bin/bash

