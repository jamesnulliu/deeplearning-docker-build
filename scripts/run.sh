CONTAINER_NAME=$1

if [ ! $CONTAINER_NAME ]; then
    CONTAINER_NAME=tmp
fi

docker run -td \
    --name $CONTAINER_NAME \
    --gpus all \
    --network=host \
    -v $HOME/Projects:/root/Projects \
    jamesnulliu/deeplearning/v1.3:torch2.6-cuda12.6-ubuntu24.04 

docker cp $HOME/.ssh $CONTAINER_NAME:/root/
docker start $CONTAINER_NAME
docker exec $CONTAINER_NAME chown -R root:root /root/.ssh
