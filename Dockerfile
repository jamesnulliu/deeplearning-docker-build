FROM nvidia/cuda:12.6.0-cudnn-devel-ubuntu24.04

LABEL maintainer="JamesNULLiu jamesnulliu@gmail.com"
LABEL version="1.4"

ARG DEBIAN_FRONTEND=noninteractive
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ARG LLVM_VERSION=21


# Some basic tools
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    git apt-utils lsb-release software-properties-common gnupg  \
    vim-gtk3 wget p7zip-full ninja-build curl jq pkg-config \
    build-essential gdb htop tmux

# Vcpkg, Cmake, LLVM
RUN cd /usr/local && git clone https://github.com/microsoft/vcpkg.git && \ 
    cd vcpkg && ./bootstrap-vcpkg.sh  && \
    wget -O /tmp/kitware-archive.sh \
    https://apt.kitware.com/kitware-archive.sh && \
    bash /tmp/kitware-archive.sh && \
    apt-get update && apt-get install -y cmake && \
    wget -O /tmp/llvm.sh https://apt.llvm.org/llvm.sh && \
    chmod +x /tmp/llvm.sh && /tmp/llvm.sh ${LLVM_VERSION} && \
    apt-get install -y libomp-${LLVM_VERSION}-dev && \
    ln -s /usr/bin/clang-${LLVM_VERSION} /usr/bin/clang && \
    ln -s /usr/bin/clang++-${LLVM_VERSION} /usr/bin/clang++ && \
    ln -s /usr/bin/clangd-${LLVM_VERSION} /usr/bin/clangd && \
    ln -s /usr/bin/clang-tidy-${LLVM_VERSION} /usr/bin/clang-tidy && \
    ln -s /usr/bin/clang-format-${LLVM_VERSION} /usr/bin/clang-format

# User config files
COPY data/.vimrc data/.inputrc data/.bashrc /tmp/
RUN mv /tmp/.bashrc /root/.bashrc && \
    mv /tmp/.vimrc /root/.vimrc && \
    mv /tmp/.inputrc /root/.inputrc

# Install Miniconda3 and conda env
RUN wget -O /tmp/miniconda3.sh \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    mkdir -p /root/miniconda3 && \
    bash /tmp/miniconda3.sh -b -u -p /root/miniconda3 && \
    \. /root/miniconda3/bin/activate && \
    conda upgrade libstdcxx-ng -c conda-forge -y && \
    pip3 install torch==2.6.0 torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu126 \
    --no-cache-dir

# Some final steps
RUN apt-get update && apt-get upgrade -y && apt-get autoremove -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    git config --system --unset-all user.name || true && \
    git config --system --unset-all user.email || true && \
    git config --global --unset-all user.name || true && \
    git config --global --unset-all user.email || true
