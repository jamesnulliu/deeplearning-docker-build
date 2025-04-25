set -e 

source ./scripts/.image-configs.sh

docker build \
    -f Dockerfile \
    --build-arg IMAGE_VERSION=$IMAGE_VERSION  \
    --build-arg TORCH_VERSION=$TORCH_VERSION \
    --build-arg CUDA_VERSION=$CUDA_VERSION \
    --build-arg UBUNTU_VERSION=$UBUNTU_VERSION \
    --build-arg CUDNN_VERSION=$CUDNN_VERSION \
    -t $IMAGE_NAME \
    .
