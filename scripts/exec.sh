CONTAINER_NAME=$1

if [ ! $CONTAINER_NAME ]; then
    CONTAINER_NAME=tmp
fi

if [ ! "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    docker start $CONTAINER_NAME
fi

docker exec -it $CONTAINER_NAME /bin/bash
