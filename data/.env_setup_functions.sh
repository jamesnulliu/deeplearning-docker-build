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
# .claude/settings.json is deliberately absent from this list: it carries your
# own model, effort, theme and permission choices, and is only ever seeded into
# a brand-new workspace by the non-clobbering copy in bootstrap.sh.
ADOPT_DEFAULT_CONFIGS() {
    local f
    for f in .bashrc .bash_profile .inputrc .tmux.conf .vimrc .npmrc \
             .env_setup.sh .env_setup_functions.sh .env_setup_banner.sh \
             .claude/statusline-command.sh; do
        [ -r "${JNL_DL_SKEL}/${f}" ] || continue
        if [ -e "${HOME}/${f}" ]; then
            cp -f "${HOME}/${f}" "${HOME}/${f}.bak"
            echo "[ENV-SETUP] Backed up ${HOME}/${f} -> ${HOME}/${f}.bak"
        fi
        mkdir -p "$(dirname "${HOME}/${f}")"
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

# @brief Absolute path to the `claude` executable npm's bin symlink points at.
#        Fails if NPM_CONFIG_PREFIX is unset or the package is not installed.
_claude_exe_path() {
    [ -n "${NPM_CONFIG_PREFIX:-}" ] || return 1
    local exe="${NPM_CONFIG_PREFIX}/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe"
    [ -f "${exe}" ] || return 1
    printf '%s\n' "${exe}"
}

# @brief True when `claude` is still npm's placeholder rather than the real
#        binary. The placeholder is ~500 bytes and the native binary ~250MB, so
#        a size test settles it without executing anything; 4096 is the same
#        threshold claude-code's own install.cjs uses to recognise its stub.
AI_CLI_NEEDS_REPAIR() {
    local exe size
    exe="$(_claude_exe_path)" || return 1
    size="$(stat -c %s "${exe}" 2>/dev/null)" || return 1
    [ "${size}" -lt 4096 ]
}

# @brief Put the real claude binary back over npm's placeholder.
#
# npm 12 runs a dependency's postinstall only if the package is listed in
# `allowScripts`. @anthropic-ai/claude-code needs its postinstall
# (`node install.cjs`) to hardlink the platform-native binary over the stub at
# bin/claude.exe; when it is blocked, `claude` only ever prints
# "Error: claude native binary not installed." -- while npm exits 0.
#
# The shipped ~/.npmrc grants that permission, which is what keeps future
# installs correct, including the ones Claude Code's auto-updater fires off on
# its own schedule. This function is the repair path for an install that has
# already gone wrong: a workspace created before that .npmrc existed, or one
# where the file was removed. No-op on a healthy install.
REPAIR_AI_CLI() {
    local exe pkg
    if ! exe="$(_claude_exe_path)"; then
        echo "[ENV-SETUP] claude-code not installed under \$NPM_CONFIG_PREFIX; run 'INSTALL_AI_CLI'."
        return 1
    fi
    pkg="$(dirname "$(dirname "${exe}")")"

    if [ ! -f "${pkg}/install.cjs" ]; then
        echo "[ENV-SETUP] ERROR: ${pkg}/install.cjs is missing; reinstall with 'INSTALL_AI_CLI'."
        return 1
    fi

    ( cd "${pkg}" && node install.cjs ) || {
        echo "[ENV-SETUP] ERROR: claude postinstall failed."
        return 1
    }

    if AI_CLI_NEEDS_REPAIR; then
        echo "[ENV-SETUP] ERROR: 'claude' is still the placeholder stub after running install.cjs."
        echo "                   The platform-native package was probably never downloaded."
        echo "                   Reinstall with: INSTALL_AI_CLI"
        return 1
    fi

    echo "[ENV-SETUP] claude native binary restored ($("${exe}" --version 2>/dev/null || echo 'version unknown'))."
}

# @brief Install the Codex and Claude CLIs into $NPM_CONFIG_PREFIX (set it first).
INSTALL_AI_CLI() {
    if [ -z "${NPM_CONFIG_PREFIX:-}" ]; then
        echo "[ENV-SETUP] ERROR: NPM_CONFIG_PREFIX is not set. Set it to a writable directory first"
        echo "                   (uncomment the suggested default in ${ENV_SETUP_FILE}), then retry."
        return 1
    fi

    # --allow-scripts repeats what ~/.npmrc already grants, so the install is
    # correct even in a workspace whose .npmrc predates it or was edited away.
    npm install -g --allow-scripts=@anthropic-ai/claude-code \
        @openai/codex @anthropic-ai/claude-code || return 1

    # npm reports success whether or not the postinstall actually ran, so verify
    # rather than trust, and repair if the placeholder is still sitting there.
    if AI_CLI_NEEDS_REPAIR; then
        echo "[ENV-SETUP] npm left the claude placeholder in place; running its postinstall."
        REPAIR_AI_CLI || return 1
    fi
}
