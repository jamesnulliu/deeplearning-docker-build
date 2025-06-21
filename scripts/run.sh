set -e

IMAGE_NAME=$1
CONTAINER_NAME=$2

if [ ! $IMAGE_NAME ]; then
    echo "Usage: $0 <image_name> [container_name]"
    exit 1
fi

if [ ! $CONTAINER_NAME ]; then 
    CONTAINER_NAME=tmp
fi

docker run -td \
    --name $CONTAINER_NAME \
    --gpus all \
    --network=host \
    --shm-size=16G \
    --hostname $CONTAINER_NAME \
    -v $HOME/Projects:/root/Projects \
    $IMAGE_NAME

docker cp $HOME/.ssh $CONTAINER_NAME:/root/
docker start $CONTAINER_NAME
docker exec $CONTAINER_NAME chown -R root:root /root/.ssh
