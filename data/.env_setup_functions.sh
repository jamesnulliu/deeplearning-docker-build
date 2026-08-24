JNL_DL_SKEL="/etc/jnl-dl/skel"

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

# @brief Force re-sync the shipped default dotfiles from /etc/jnl-dl/skel
#        into $HOME, backing up existing files to "<file>.bak" first. Your
#        workspace is already seeded automatically on first shell (see
#        /etc/jnl-dl/bootstrap.sh) -- use this only when you deliberately
#        want to overwrite your own edits with the latest shipped defaults.
ADOPT_DEFAULT_CONFIGS() {
    local f
    for f in .bashrc .bash_profile .inputrc .tmux.conf .vimrc \
             .env_setup.sh .env_setup_functions.sh .env_setup_banner.sh; do
        [ -r "${JNL_DL_SKEL}/${f}" ] || continue
        if [ -e "${HOME}/${f}" ]; then
            cp -f "${HOME}/${f}" "${HOME}/${f}.bak"
            echo "[ENV-SETUP] Backed up ${HOME}/${f} -> ${HOME}/${f}.bak"
        fi
        cp -f "${JNL_DL_SKEL}/${f}" "${HOME}/${f}"
        echo "[ENV-SETUP] Installed ${JNL_DL_SKEL}/${f} -> ${HOME}/${f}"
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
    npm install -g @openai/codex @anthropic-ai/claude-code || return 1

    # @anthropic-ai/claude-code ships a tiny stub at bin/claude.exe and relies on
    # its postinstall to hardlink the ~300MB platform-native binary over that stub.
    # npm's optional-dependency ordering (and later auto-update reinstalls) can
    # skip that step, leaving `claude` as the "native binary not installed" stub --
    # baked into the persisted npm-global home so it survives container restarts.
    # Re-run the postinstall explicitly to place the binary, then verify it launches.
    local cc_pkg="${NPM_CONFIG_PREFIX}/lib/node_modules/@anthropic-ai/claude-code"
    if [ -f "${cc_pkg}/install.cjs" ]; then
        ( cd "${cc_pkg}" && node install.cjs ) || true
    fi

    if command -v claude > /dev/null 2>&1 && ! claude --version > /dev/null 2>&1; then
        echo "[ENV-SETUP] WARNING: 'claude' is on PATH but its native binary failed to launch."
        echo "                     Try: ( cd '${cc_pkg}' && node install.cjs )"
    fi
}
