CONTAINER_NAME=$1

if [ ! $CONTAINER_NAME ]; then
    CONTAINER_NAME=tmp
fi

# [NOTE]
#   1. The default entrypoint is `/opt/nvidia/nvidia_entrypoint.sh`, which
#      checks the system compatibility, prints the license and infomation, and 
#      finally runs `/bin/bash`. After the container is created, you can use
#      `/bin/bash` to enter the container directly (for example: `docker exec 
#      -it <name> /bin/bash` since there is no need to check again.
docker run -it \
    --name $CONTAINER_NAME \
    --gpus all \
    --network=host \
    -v $HOME/Projects:/root/Projects \
    jamesnulliu/deeplearning:torch2.6-cuda12.6-ubuntu24.04 

docker cp $HOME/.ssh $CONTAINER_NAME:/root/
docker start $CONTAINER_NAME
docker exec $CONTAINER_NAME chown -R root:root /root/.ssh
