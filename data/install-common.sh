#!/usr/bin/env bash

set -euxo pipefail

print_help() {
    cat <<'EOF'
Usage: /usr/local/bin/install-common.sh

Install the shared toolchain and utilities used by both Docker image variants.

Environment:
  LLVM_VERSION          LLVM major version to install. Required.
  UV_HOME               Target directory for uv. Required.
  RUSTUP_HOME           Shared Rust toolchain store, for example /usr/local/rustup. Required.
  TZ                    Optional timezone name to configure, for example Etc/UTC.
EOF
}

case "${1:-}" in
    -h|--help)
        print_help
        exit 0
        ;;
esac

export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"

apt-get update
apt-get install -y --no-install-recommends \
    apt-utils \
    lsb-release \
    software-properties-common \
    gnupg \
    git \
    acl \
    sed \
    vim-gtk3 \
    wget \
    p7zip-full \
    zip \
    unzip \
    tar \
    ninja-build \
    curl \
    jq \
    nodejs \
    npm \
    pkg-config \
    openssh-client \
    sudo \
    ccache \
    build-essential \
    gdb \
    htop \
    tmux \
    kmod \
    bubblewrap \
    libssl-dev \
    tzdata \
    ca-certificates

echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" \
    | debconf-set-selections
apt-get install -y --no-install-recommends ttf-mscorefonts-installer
fc-cache -f -v

if [ -n "${TZ:-}" ]; then
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
    echo "${TZ}" > /etc/timezone
fi

wget -O /tmp/kitware-archive.sh https://apt.kitware.com/kitware-archive.sh
bash /tmp/kitware-archive.sh
apt-get update
apt-get install -y --no-install-recommends cmake

wget -O /tmp/llvm.sh https://apt.llvm.org/llvm.sh
chmod +x /tmp/llvm.sh
/tmp/llvm.sh "${LLVM_VERSION}"
apt-get update
apt-get install -y --no-install-recommends \
    "clang-${LLVM_VERSION}" \
    "lldb-${LLVM_VERSION}" \
    "clang-tools-${LLVM_VERSION}" \
    "libclang-${LLVM_VERSION}-dev" \
    "clang-format-${LLVM_VERSION}" \
    "libomp-${LLVM_VERSION}-dev" \
    "clangd-${LLVM_VERSION}" \
    "clang-tidy-${LLVM_VERSION}" \
    "libc++-${LLVM_VERSION}-dev" \
    "libc++abi-${LLVM_VERSION}-dev"

ln -sf "/usr/bin/clang-${LLVM_VERSION}" /usr/bin/clang
ln -sf "/usr/bin/clang++-${LLVM_VERSION}" /usr/bin/clang++
ln -sf "/usr/bin/clangd-${LLVM_VERSION}" /usr/bin/clangd
ln -sf "/usr/bin/clang-tidy-${LLVM_VERSION}" /usr/bin/clang-tidy
ln -sf "/usr/bin/clang-format-${LLVM_VERSION}" /usr/bin/clang-format
ln -sf "/usr/bin/lldb-${LLVM_VERSION}" /usr/bin/lldb

# Install Rust into a shared, root-owned location. cargo/rustc/rustup are exposed
# on the default PATH via /usr/local/bin symlinks, so every user can build without
# any env var. CARGO_HOME is deliberately NOT persisted as an image env var: at
# runtime cargo falls back to ~/.cargo (writable per user) unless the user sets it.
# RUSTUP_HOME (from the image env) is the shared, read-only toolchain store.
curl https://sh.rustup.rs -sSf | \
    env CARGO_HOME=/usr/local/cargo sh -s -- -y --no-modify-path
ln -sf /usr/local/cargo/bin/* /usr/local/bin/

curl -LsSf https://astral.sh/uv/install.sh | \
    env UV_INSTALL_DIR="${UV_HOME}" UV_NO_MODIFY_PATH=1 sh

# The container toolchain environment ($ENV_SETUP_FILE) is sourced from
# data/bashrc, which is the only file entrypoint.sh seeds automatically (the
# minimum needed for bash to have any hook at all in a fresh workspace home).
# Everything else -- the user's own persistent env_setup.sh copy, the other
# dotfiles, ~/.ssh/~/.gitconfig linking -- is opt-in via ADOPT_DEFAULT_CONFIGS
# and LINK_HOST_IDENTITY, both defined in data/env_setup.sh and surfaced in
# the seeded ~/.bashrc's startup banner.

# Passwordless sudo for whichever host user/uid the container resolves to via
# the bind-mounted /etc/passwd -- the image is built once but run as different
# host users at runtime, so a fixed username can't be baked in here.
install -d -m 0755 /etc/sudoers.d
printf '%s\n' 'ALL ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/nopasswd-all
chmod 0440 /etc/sudoers.d/nopasswd-all
visudo -cf /etc/sudoers.d/nopasswd-all

apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -f /tmp/kitware-archive.sh /tmp/llvm.sh

git config --system --unset-all user.name || true
git config --system --unset-all user.email || true
git config --global --unset-all user.name || true
git config --global --unset-all user.email || true
