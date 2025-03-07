CONTAINER_NAME=$1

if [ ! $CONTAINER_NAME ]; then
    CONTAINER_NAME=tmp
fi

# [NOTE]
#   1. With `-rm` option, this contianer will be removed after you exit.
docker run -rm \
    -it \
    --name $CONTAINER_NAME \
    --gpus all \
    --network=host \
    -v $HOME/Projects:/root/Projects \
    jamesnulliu/deeplearning:torch2.6-cuda12.6-ubuntu24.04 

