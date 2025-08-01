echo "[ENV-SETUP] Setting up environment with: ${ENV_SETUP_FILE}"

# @brief Add `$1` into environment variable `$2` if it is not already there.
# @example > env_load PATH /usr/local/bin
env_load() {
    local var_name=$1
    local new_path=$2
    if [[ ":${!var_name}:" != *":$new_path:"* ]]; then
        export "$var_name"="${!var_name:+"${!var_name}:"}$new_path"
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

if [ -d "${CONDA_HOME:-}" ]; then
    if [[ $- == *i* ]]; then
        # Initialize conda in interactive mode
        __conda_setup="$('${CONDA_HOME}/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
        if [ $? -eq 0 ]; then
            eval "$__conda_setup"
        else
            if [ -f "${CONDA_HOME}/etc/profile.d/conda.sh" ]; then
                . "${CONDA_HOME}/etc/profile.d/conda.sh"
            else
                env_load PATH "${CONDA_HOME}/bin"
            fi
        fi
        unset __conda_setup
        echo "[ENV-SETUP] Conda initialized in interactive mode from $CONDA_HOME"
    else
        # Initialize conda in non-interactive mode
        # Note that you may have to use `conda run` to use conda environments
        . "${CONDA_HOME}/etc/profile.d/conda.sh" 
        echo "[ENV-SETUP] Conda initialized in non-interactive mode from $CONDA_HOME."
    fi
else
    unset CONDA_HOME
fi

if [ -d "${CUDA_HOME:-}" ]; then
    alias LOAD_CUDA="env_load PATH $CUDA_HOME/bin && \
        env_load LD_LIBRARY_PATH $CUDA_HOME/lib64"
    alias UNLOAD_CUDA="env_unload PATH $CUDA_HOME/bin && \
        env_unload LD_LIBRARY_PATH $CUDA_HOME/lib64"
    env_load PATH "$CUDA_HOME/bin"
    env_load LD_LIBRARY_PATH "$CUDA_HOME/lib64"
    echo "[ENV-SETUP] CUDA initialized from $CUDA_HOME"
else
    unset CUDA_HOME
fi

if [ -d "${VCPKG_HOME:-}" ]; then
    alias LOAD_VCPKG="env_load PATH $VCPKG_HOME"
    alias UNLOAD_VCPKG="env_unload PATH $VCPKG_HOME"
    alias VCPKG_UPDATE="pushd $VCPKG_HOME && git pull && popd"
    # Load vcpkg by default
    env_load PATH "$VCPKG_HOME"
    echo "[ENV-SETUP] VCPKG initialized from $VCPKG_HOME"
else
    unset VCPKG_HOME
fi