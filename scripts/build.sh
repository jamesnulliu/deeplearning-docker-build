IMAGE_NAME=$1

docker build \
    -f Dockerfile \
    -t $IMAGE_NAME \
    .
