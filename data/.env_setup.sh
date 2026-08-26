FILE_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
FILE_NAME="$( basename -- "${BASH_SOURCE[0]}" )"
FILE_PATH="$FILE_DIR/$FILE_NAME"

# Banner + helper functions live in sibling files, copied alongside this one.
source "${FILE_DIR}/.env_setup_banner.sh"
source "${FILE_DIR}/.env_setup_functions.sh"

echo "[ENV-SETUP] Sourcing ${FILE_PATH}"
echo "            ENV_SETUP_FILE: ${ENV_SETUP_FILE:-<not set>}"
echo ""

# Dotfiles
echo "[ENV-SETUP] Default configs live in ${JNL_DL_SKEL}, seeded into \$HOME"
echo "            run 'ADOPT_DEFAULT_CONFIGS' to force re-sync updated defaults."

if [ -e "${HOME}/.ssh" ] || [ -e "${HOME}/.gitconfig" ]; then
    echo "[ENV-SETUP] Host identity: linked"
else
    echo "[ENV-SETUP] Host identity: no separate host home detected to link from"
fi

# Editor
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-vim}"
echo "[ENV-SETUP] EDITOR: ${EDITOR}"
echo "            VISUAL: ${VISUAL}"
# Terminal colors
case "${TERM:-}" in
    *256color*|*-direct) ;;
    *) export TERM="xterm-256color" ;;
esac
export COLORTERM="${COLORTERM:-truecolor}"
echo "            TERM: ${TERM}"
echo "            COLORTERM: ${COLORTERM}"

# Time zone
# export TZ="Etc/UTC"
echo "[ENV-SETUP] TZ: ${TZ:-<not set>}"

# CUDA
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

# vcpkg
# export VCPKG_ROOT="$HOME/.local/share/vcpkg"
echo "[ENV-SETUP] VCPKG_ROOT: ${VCPKG_ROOT:-<not set>}"
if [ -n "${VCPKG_ROOT:-}" ] && [ -x "${VCPKG_ROOT}/vcpkg" ]; then
    alias LOAD_VCPKG="env_load PATH $VCPKG_ROOT"
    alias UNLOAD_VCPKG="env_unload PATH $VCPKG_ROOT"
    alias VCPKG_UPDATE="pushd $VCPKG_ROOT && git pull && popd"
    env_load PATH "$VCPKG_ROOT"
    echo "            |- vcpkg found; added to PATH"
elif [ -n "${VCPKG_ROOT:-}" ]; then
    echo "            |- not installed here; run 'INSTALL_VCPKG'"
fi

# uv
echo "[ENV-SETUP] UV_HOME: ${UV_HOME:-<not set>}"
if [ -n "${UV_HOME:-}" ] && [ -d "${UV_HOME}" ]; then
    alias LOAD_UV="env_load PATH $UV_HOME"
    alias UNLOAD_UV="env_unload PATH $UV_HOME"
    env_load PATH "$UV_HOME"
    echo "            |- added to PATH"
else
    unset UV_HOME
fi
# export UV_CACHE_DIR="$HOME/.cache/uv"
# export UV_PYTHON_INSTALL_DIR="$HOME/.local/share/uv/python"
echo "            |- UV_CACHE_DIR: ${UV_CACHE_DIR:-<not set>}"
echo "            |- UV_PYTHON_INSTALL_DIR: ${UV_PYTHON_INSTALL_DIR:-<not set>}"

# Rust
# export CARGO_HOME="$HOME/.cargo"
echo "[ENV-SETUP] RUSTUP_HOME: ${RUSTUP_HOME:-<not set>}"
echo "            |- CARGO_HOME: ${CARGO_HOME:-<not set>}"
if [ -n "${CARGO_HOME:-}" ]; then
    env_load PATH "$CARGO_HOME/bin"
    echo "            |- \$CARGO_HOME/bin added to PATH"
fi

# Node / AI CLIs
# export NPM_CONFIG_PREFIX="$HOME/.local/share/npm-global"
echo "[ENV-SETUP] NPM_CONFIG_PREFIX: ${NPM_CONFIG_PREFIX:-<not set>}"
if [ -n "${NPM_CONFIG_PREFIX:-}" ]; then
    env_load PATH "$NPM_CONFIG_PREFIX/bin"
    echo "            |- \$NPM_CONFIG_PREFIX/bin added to PATH"
fi
if command -v codex > /dev/null 2>&1 && command -v claude > /dev/null 2>&1; then
    # Being on PATH is not the same as working. When npm blocks claude-code's
    # postinstall (see ~/.npmrc) the `claude` on PATH is a placeholder that only
    # prints an error. Check here rather than leaving it for first use: Claude
    # Code's auto-updater reinstalls on its own schedule, so a workspace that
    # worked yesterday can come back broken with nothing having changed locally.
    if AI_CLI_NEEDS_REPAIR; then
        echo "            |- claude is the placeholder stub (npm blocked its postinstall); repairing"
        REPAIR_AI_CLI
    else
        echo "            |- codex and claude found on PATH"
    fi
else
    echo "            |- codex/claude not found; run 'INSTALL_AI_CLI'"
fi
