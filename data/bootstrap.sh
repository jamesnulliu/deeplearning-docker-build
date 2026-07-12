# /etc/jnl-dl/bootstrap.sh
#
# Dot-sourced by /etc/bash.bashrc and /etc/profile.d/00-jnl-dl.sh for every
# interactive bash shell -- unlike entrypoint.sh, this runs regardless of
# container runtime (Docker exec, Apptainer shell/exec, a bare
# `docker run --entrypoint bash`, ...), since it's plain bash startup-file
# behavior, not something Docker's ENTRYPOINT controls.
#
# The only thing this does automatically is copy missing files from
# /etc/jnl-dl/skel into $HOME (exactly like /etc/skel does for
# `useradd -m`) and symlink ~/.ssh/~/.gitconfig from your real host home.
# Existing files are NEVER touched. `cat` this file any time to see exactly
# what ran.
#
# No `set -e`/`set -u` here: this is sourced into a live interactive shell,
# not run as its own script, so setting shell options here would silently
# change the caller's shell after it returns.

JNL_DL_SKEL="/etc/jnl-dl/skel"

if [ -n "${HOME:-}" ] && [ -d "${JNL_DL_SKEL}" ]; then
    mkdir -p "${HOME}" 2>/dev/null

    if [ -e "${HOME}/.bashrc" ]; then
        echo "[jnl-dl] Workspace ${HOME}: already set up (left untouched; any files you don't have yet are still added below)."
    else
        echo "[jnl-dl] Workspace ${HOME}: new -- seeding default configs from ${JNL_DL_SKEL}."
    fi
    cp -rvn "${JNL_DL_SKEL}/." "${HOME}/" 2>/dev/null | sed 's/^/[jnl-dl] /'

    JNL_DL_REAL_HOME="$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6)"
    if [ -n "${JNL_DL_REAL_HOME}" ] && [ "${JNL_DL_REAL_HOME}" != "${HOME}" ]; then
        if [ -d "${JNL_DL_REAL_HOME}/.ssh" ] && [ ! -e "${HOME}/.ssh" ]; then
            ln -s "${JNL_DL_REAL_HOME}/.ssh" "${HOME}/.ssh"
            echo "[jnl-dl] Linked ${HOME}/.ssh -> ${JNL_DL_REAL_HOME}/.ssh"
        fi
        if [ -f "${JNL_DL_REAL_HOME}/.gitconfig" ] && [ ! -e "${HOME}/.gitconfig" ]; then
            ln -s "${JNL_DL_REAL_HOME}/.gitconfig" "${HOME}/.gitconfig"
            echo "[jnl-dl] Linked ${HOME}/.gitconfig -> ${JNL_DL_REAL_HOME}/.gitconfig"
        fi
    fi
    unset JNL_DL_REAL_HOME
fi
unset JNL_DL_SKEL

export ENV_SETUP_FILE="${HOME}/.env_setup.sh"
if [ -r "${ENV_SETUP_FILE}" ]; then
    . "${ENV_SETUP_FILE}"
fi
