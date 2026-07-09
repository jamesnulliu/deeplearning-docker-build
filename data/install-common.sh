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
  ENV_SETUP_FILE        Path to the container env-setup script to auto-source. Required.
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

# Auto-source the container env-setup script for every interactive bash shell,
# for any user, without touching their personal dotfiles. env_setup.sh guards
# itself against double-sourcing within a single shell process.
ENV_SETUP_HOOK="$(cat <<'HOOK'

# Auto-load the container toolchain environment (added by install-common.sh).
if [ -n "${BASH_VERSION:-}" ] && [ -n "${ENV_SETUP_FILE:-}" ] && [ -r "${ENV_SETUP_FILE}" ]; then
    . "${ENV_SETUP_FILE}"
fi
HOOK
)"

# Login shells (/etc/profile -> /etc/profile.d/*.sh).
printf '%s\n' "${ENV_SETUP_HOOK}" > /etc/profile.d/00-env-setup.sh
chmod 0644 /etc/profile.d/00-env-setup.sh

# Interactive non-login shells (e.g. `docker exec -it <ctr> bash`). Ubuntu's
# /etc/bash.bashrc returns early for non-interactive shells, so scripts are safe.
printf '%s\n' "${ENV_SETUP_HOOK}" >> /etc/bash.bashrc

apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -f /tmp/kitware-archive.sh /tmp/llvm.sh

git config --system --unset-all user.name || true
git config --system --unset-all user.email || true
git config --global --unset-all user.name || true
git config --global --unset-all user.email || true
