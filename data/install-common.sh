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

# Node.js -- Ubuntu's own nodejs/npm packages are frozen at an old major
# version (18.x on 24.04), which is too old for current CLI tools (e.g.
# @anthropic-ai/claude-code requires node >=22) and ships an equally old npm
# to match. Use NodeSource's setup script for a current LTS release instead.
NODE_MAJOR=22
wget -O /tmp/nodesource_setup.sh "https://deb.nodesource.com/setup_${NODE_MAJOR}.x"
bash /tmp/nodesource_setup.sh
apt-get install -y --no-install-recommends nodejs

# The npm bundled inside a Node release is frozen at whatever was current when
# that Node was cut, so even a current node 22 still carries an npm 10 -- older
# than the `allow-scripts` permission model npm 12 introduced. The shipped
# ~/.npmrc and INSTALL_AI_CLI are written against that model (see data/.npmrc
# for why claude-code needs it) and are inert on npm 10, so the image would
# behave differently from the one those files were written for. Track current
# npm instead: it installs over the bundled copy in /usr/lib/node_modules, so
# every user gets it, and a per-user NPM_CONFIG_PREFIX only redirects where
# packages land, not which npm runs.
npm install -g npm@latest
npm --version

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

# Minimal, transparent, non-destructive hook -- works under any runtime
# that runs a plain bash shell (Docker exec, Apptainer shell/exec, a bare
# `docker run --entrypoint bash`, ...), not just this image's ENTRYPOINT.
# `cat /etc/jnl-dl/bootstrap.sh` shows exactly what it does; it never
# overwrites anything in $HOME.
JNL_DL_HOOK='[ -r /etc/jnl-dl/bootstrap.sh ] && . /etc/jnl-dl/bootstrap.sh'
printf '\n# jnl-dl workspace bootstrap (see /etc/jnl-dl/bootstrap.sh)\n%s\n' \
    "${JNL_DL_HOOK}" >> /etc/bash.bashrc
install -d -m 0755 /etc/profile.d
printf '# jnl-dl workspace bootstrap for login shells (see /etc/jnl-dl/bootstrap.sh)\n%s\n' \
    "${JNL_DL_HOOK}" > /etc/profile.d/00-jnl-dl.sh
chmod 0644 /etc/profile.d/00-jnl-dl.sh

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
rm -f /tmp/kitware-archive.sh /tmp/llvm.sh /tmp/nodesource_setup.sh

git config --system --unset-all user.name || true
git config --system --unset-all user.email || true
git config --global --unset-all user.name || true
git config --global --unset-all user.email || true
