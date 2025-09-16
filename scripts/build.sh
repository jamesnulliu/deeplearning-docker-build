set -e 

DOCKER_FILE=$1

source ./scripts/image-configs.sh

if [[ "${DOCKER_FILE}" == *.cpu ]]; then 
    IMAGE_TAG="${IMAGE_TAG}-cpu"
elif [[ "${DOCKER_FILE}" == *.cuda ]]; then 
    IMAGE_TAG="${IMAGE_TAG}-cuda${CUDA_VERSION}"
fi

IMAGE_NAME=jamesnulliu/deeplearning:${IMAGE_TAG}

docker build \
    -f $DOCKER_FILE \
    --build-arg IMAGE_VERSION=$IMAGE_VERSION \
    --build-arg IMAGE_NAME=$IMAGE_NAME \
    --build-arg UBUNTU_VERSION=$UBUNTU_VERSION \
    --build-arg LLVM_VERSION=$LLVM_VERSION \
    --build-arg CUDA_VERSION=$CUDA_VERSION \
    -t $IMAGE_NAME \
    .

echo "$IMAGE_NAME"