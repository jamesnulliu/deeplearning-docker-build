# @ https://patorjk.com/software/taag/?p=display&f=Varsity&t=JNL%2FDL&x=none

# Guard against double-sourcing within a single shell process (e.g. sourced by
# both /etc/bash.bashrc and a personal ~/.bashrc). The variable is intentionally
# not exported, so every new interactive shell still loads the environment once.
if [ -n "${__ENV_SETUP_DONE:-}" ]; then
    return 0 2>/dev/null || true
fi
__ENV_SETUP_DONE=1

sed "s|\${IMAGE_NAME}|${IMAGE_NAME}|g" << 'EOF'
===============================================================================
        _____   ____  _____    _____          __  ______      _____
       |_   _| |_   \|_   _|  |_   _|        / / |_   _ `.   |_   _|
         | |     |   \ | |      | |         / /    | | `. \    | |
     _   | |     | |\ \| |      | |   _    / /     | |  | |    | |   _
    | |__' |    _| |_\   |_    _| |__/ |  / /     _| |_.' /   _| |__/ |
    `.____.'   |_____|\____|  |________| /_/     |______.'   |________|

-------------------------------------------------------------------------------
Image Name:  ${IMAGE_NAME}
Creator:     JamesNULLiu <jamesnulliu@gmail.com>
License:     MIT
===============================================================================
EOF

FILE_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
FILE_NAME="$( basename -- "${BASH_SOURCE[0]}" )"
FILE_PATH="$FILE_DIR/$FILE_NAME"

echo "[ENV-SETUP] Sourcing ${FILE_PATH}"
echo "            ENV_SETUP_FILE: ${ENV_SETUP_FILE:-<not set>}"
echo "            NOTE: state/cache directories below are intentionally NOT defaulted."
echo "                  Uncomment a suggested default in this file (or export your own)"
echo "                  so you always know where things live across container versions."

# @brief Add `$1` into environment variable `$2` if it is not already there.
# @example > env_load PATH /usr/local/bin
env_load() {
    local var_name=$1
    local new_path=$2
    if [[ ":${!var_name}:" != *":$new_path:"* ]]; then
        export "$var_name"="$new_path${!var_name:+":${!var_name}"}"
    fi
}

# @brief Remove `$1` from environment variable `$2` if it is there.
# @example > env_unload PATH /usr/local/bin
env_unload() {
    local var_name=$1
    local target_path=$2
    local paths_array=(${!var_name//:/ })
    local new_paths=()
    for item in "${paths_array[@]}"; do
        if [[ "$item" != "$target_path" ]]; then
            new_paths+=("$item")
        fi
    done
    export $var_name=$(IFS=:; echo "${new_paths[*]}")
}

# @brief Copy the container default dotfiles into $HOME. Existing files are
#        backed up to "<file>.bak" first, so your own configs are never lost.
ADOPT_DEFAULT_CONFIGS() {
    local pair src dst
    for pair in \
        "${CONTAINER_DEFAULT_BASHRC}=${HOME}/.bashrc" \
        "${CONTAINER_DEFAULT_BASH_PROFILE}=${HOME}/.bash_profile" \
        "${CONTAINER_DEFAULT_INPUTRC}=${HOME}/.inputrc" \
        "${CONTAINER_DEFAULT_TMUX_CONF}=${HOME}/.tmux.conf"; do
        src="${pair%%=*}"
        dst="${pair##*=}"
        [ -r "$src" ] || continue
        if [ -e "$dst" ]; then
            cp -f "$dst" "$dst.bak"
            echo "[ENV-SETUP] Backed up $dst -> $dst.bak"
        fi
        cp -f "$src" "$dst"
        echo "[ENV-SETUP] Installed $src -> $dst"
    done
}

# @brief Clone and bootstrap vcpkg into $VCPKG_ROOT (which you must set first).
INSTALL_VCPKG() {
    if [ -z "${VCPKG_ROOT:-}" ]; then
        echo "[ENV-SETUP] ERROR: VCPKG_ROOT is not set. Set it to a writable directory first"
        echo "                   (uncomment the suggested default in ${ENV_SETUP_FILE}), then retry."
        return 1
    fi
    if [ -x "${VCPKG_ROOT}/vcpkg" ]; then
        echo "[ENV-SETUP] vcpkg already installed at ${VCPKG_ROOT}"
        return 0
    fi
    git clone https://github.com/microsoft/vcpkg.git "${VCPKG_ROOT}" && \
    "${VCPKG_ROOT}/bootstrap-vcpkg.sh" && \
    echo "[ENV-SETUP] vcpkg installed. Open a new shell (or re-source ${ENV_SETUP_FILE}) to load it onto PATH."
}

# @brief Install the Codex and Claude CLIs into $NPM_CONFIG_PREFIX (set it first).
INSTALL_AI_CLI() {
    if [ -z "${NPM_CONFIG_PREFIX:-}" ]; then
        echo "[ENV-SETUP] ERROR: NPM_CONFIG_PREFIX is not set. Set it to a writable directory first"
        echo "                   (uncomment the suggested default in ${ENV_SETUP_FILE}), then retry."
        return 1
    fi
    npm install -g @openai/codex @anthropic-ai/claude-code
}

# Time zone:
#   To set a default time zone for interactive shells, edit this file manually
#   and uncomment the following line with your preferred value.
# export TZ="Etc/UTC"
echo "[ENV-SETUP] TZ: ${TZ:-<not set>}"

# ---------------------------------------------------------------------------
# CUDA -- baked into the image at CUDA_HOME (a fixed install location).
# ---------------------------------------------------------------------------
echo "[ENV-SETUP] CUDA_HOME: ${CUDA_HOME:-<not set>}"
if [ -n "${CUDA_HOME:-}" ] && [ -d "${CUDA_HOME}" ]; then
    alias LOAD_CUDA="env_load PATH $CUDA_HOME/bin && \
        env_load LD_LIBRARY_PATH $CUDA_HOME/lib64"
    alias UNLOAD_CUDA="env_unload PATH $CUDA_HOME/bin && \
        env_unload LD_LIBRARY_PATH $CUDA_HOME/lib64"
    env_load PATH "$CUDA_HOME/bin"
    env_load LD_LIBRARY_PATH "$CUDA_HOME/lib64"
    echo "            |- added to PATH and LD_LIBRARY_PATH"
else
    unset CUDA_HOME
fi

# ---------------------------------------------------------------------------
# vcpkg -- installed per-user and never defaulted, so you always control where
# the tree lives. Uncomment the line below to use the suggested location:
# export VCPKG_ROOT="$HOME/.local/share/vcpkg"
# ---------------------------------------------------------------------------
echo "[ENV-SETUP] VCPKG_ROOT: ${VCPKG_ROOT:-<not set>}"
if [ -n "${VCPKG_ROOT:-}" ] && [ -x "${VCPKG_ROOT}/vcpkg" ]; then
    alias LOAD_VCPKG="env_load PATH $VCPKG_ROOT"
    alias UNLOAD_VCPKG="env_unload PATH $VCPKG_ROOT"
    alias VCPKG_UPDATE="pushd $VCPKG_ROOT && git pull && popd"
    env_load PATH "$VCPKG_ROOT"
    echo "            |- vcpkg found; added to PATH"
elif [ -n "${VCPKG_ROOT:-}" ]; then
    echo "            |- not installed here; run 'INSTALL_VCPKG' to bootstrap it into VCPKG_ROOT"
else
    echo "            |- unset; set VCPKG_ROOT (see commented default above), then run 'INSTALL_VCPKG'"
fi

# ---------------------------------------------------------------------------
# uv -- baked into the image at UV_HOME (a fixed install location). Its cache
# and Python install directories are yours to set (uv has its own defaults).
# ---------------------------------------------------------------------------
echo "[ENV-SETUP] UV_HOME: ${UV_HOME:-<not set>}"
if [ -n "${UV_HOME:-}" ] && [ -d "${UV_HOME}" ]; then
    alias LOAD_UV="env_load PATH $UV_HOME"
    alias UNLOAD_UV="env_unload PATH $UV_HOME"
    env_load PATH "$UV_HOME"
    echo "            |- added to PATH"
else
    unset UV_HOME
fi
# To relocate uv state, set these in your shell:
#   export UV_CACHE_DIR="$HOME/.cache/uv"
#   export UV_PYTHON_INSTALL_DIR="$HOME/.local/share/uv/python"
echo "            |- UV_CACHE_DIR: ${UV_CACHE_DIR:-<not set>}"
echo "            |- UV_PYTHON_INSTALL_DIR: ${UV_PYTHON_INSTALL_DIR:-<not set>}"

# ---------------------------------------------------------------------------
# Rust -- toolchain baked in; cargo/rustc/rustup are on PATH via /usr/local/bin
# symlinks, and RUSTUP_HOME is the shared, read-only toolchain store. CARGO_HOME
# is never baked: cargo falls back to ~/.cargo. Uncomment to relocate its state
# and add its bin dir to PATH:
# export CARGO_HOME="$HOME/.cargo"
# ---------------------------------------------------------------------------
echo "[ENV-SETUP] RUSTUP_HOME: ${RUSTUP_HOME:-<not set>}"
echo "            |- CARGO_HOME: ${CARGO_HOME:-<not set>}"
if [ -n "${CARGO_HOME:-}" ]; then
    env_load PATH "$CARGO_HOME/bin"
    echo "            |- \$CARGO_HOME/bin added to PATH"
else
    echo "            |- unset; cargo uses ~/.cargo (see commented default above to relocate)"
fi

# ---------------------------------------------------------------------------
# Node / AI CLIs -- set NPM_CONFIG_PREFIX to a writable npm global prefix so
# codex/claude install somewhere you own. Never defaulted. Uncomment the line
# below to use the suggested location:
# export NPM_CONFIG_PREFIX="$HOME/.local/share/npm-global"
# ---------------------------------------------------------------------------
echo "[ENV-SETUP] NPM_CONFIG_PREFIX: ${NPM_CONFIG_PREFIX:-<not set>}"
if [ -n "${NPM_CONFIG_PREFIX:-}" ]; then
    env_load PATH "$NPM_CONFIG_PREFIX/bin"
    echo "            |- \$NPM_CONFIG_PREFIX/bin added to PATH"
else
    echo "            |- unset; set NPM_CONFIG_PREFIX (see commented default above), then run 'INSTALL_AI_CLI'"
fi
if command -v codex > /dev/null 2>&1 && command -v claude > /dev/null 2>&1; then
    echo "            |- codex and claude found on PATH"
else
    echo "            |- codex/claude not found; run 'INSTALL_AI_CLI' after setting NPM_CONFIG_PREFIX"
fi

# ---------------------------------------------------------------------------
# Container default dotfiles (copy into your home to adopt them).
# ---------------------------------------------------------------------------
echo "[ENV-SETUP] Container default configs (run 'ADOPT_DEFAULT_CONFIGS' to copy into \$HOME):"
echo "            |- CONTAINER_DEFAULT_BASHRC:       ${CONTAINER_DEFAULT_BASHRC:-<not set>}"
echo "            |- CONTAINER_DEFAULT_BASH_PROFILE: ${CONTAINER_DEFAULT_BASH_PROFILE:-<not set>}"
echo "            |- CONTAINER_DEFAULT_INPUTRC:      ${CONTAINER_DEFAULT_INPUTRC:-<not set>}"
echo "            |- CONTAINER_DEFAULT_TMUX_CONF:    ${CONTAINER_DEFAULT_TMUX_CONF:-<not set>}"
