set -e 

source ./scripts/.image-configs.sh
echo $IMAGE_VERSION

docker build \
    -f Dockerfile \
    --build-arg VERSION=$IMAGE_VERSION \
    -t $IMAGE_NAME \
    .
