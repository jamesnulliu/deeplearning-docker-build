set -e 

DOCKER_FILE=$1

source ./scripts/.image-configs.sh

if [[ "${DOCKER_FILE}" == *.cpu ]]; then IMAGE_TAG="${IMAGE_TAG}-cpu"; fi
if [[ "${DOCKER_FILE}" == *.cuda ]]; then IMAGE_TAG="${IMAGE_TAG}-cuda${CUDA_VERSION}"; fi
if [[ "${INSTALL_TORCH}" == "true" ]]; then IMAGE_TAG="${IMAGE_TAG}-torch${TORCH_VERSION}"; fi
if [[ "${INSTALL_LLVM}" == "true" ]]; then IMAGE_TAG="${IMAGE_TAG}-llvm${LLVM_VERSION}"; fi

IMAGE_NAME=jamesnulliu/deeplearning:${IMAGE_TAG}

docker build \
    -f $DOCKER_FILE \
    --build-arg INSTALL_LLVM=$INSTALL_LLVM \
    --build-arg INSTALL_TORCH=$INSTALL_TORCH \
    --build-arg IMAGE_VERSION=$IMAGE_VERSION \
    --build-arg TORCH_VERSION=$TORCH_VERSION \
    --build-arg CUDA_VERSION=$CUDA_VERSION \
    --build-arg UBUNTU_VERSION=$UBUNTU_VERSION \
    --build-arg CUDNN_VERSION=$CUDNN_VERSION \
    --build-arg LLVM_VERSION=$LLVM_VERSION \
    -t $IMAGE_NAME \
    .

echo "$IMAGE_NAME"