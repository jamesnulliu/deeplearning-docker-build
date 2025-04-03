CONTAINER_NAME=$1

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
    jamesnulliu/deeplearning:torch2.6-cuda12.6-ubuntu24.04

