#!/bin/bash
set -e

# @brief Add `$1` into environment variable `$2` if it is not already there.
# @example > env_load PATH /usr/local/bin
env_load() {
    local env_var=$1
    local path=$2
    if [[ ":${!env_var}:" != *":$path:"* ]]; then
        export $env_var="${!env_var}:$path"
    fi
}

# @brief Remove `$1` from environment variable `$2` if it is there.
# @example > env_unload PATH /usr/local/bin
env_unload() {
    local env_var=$1
    local path=$2
    local paths_array=(${!env_var//:/ })
    local new_paths=()
    for item in "${paths_array[@]}"; do
        if [[ "$item" != "$path" ]]; then
            new_paths+=("$item")
        fi
    done
    export $env_var=$(IFS=:; echo "${new_paths[*]}")
}

# Source the conda setup script
# >>> conda initialize >>>
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
# <<< conda initialize <<<

if [ -d "$CUDA_HOME" ]; then
    env_load PATH $CUDA_HOME/bin
    env_load LD_LIBRARY_PATH $CUDA_HOME/lib64
else
    unset CUDA_HOME
fi
env_load PATH $VCPKG_HOME

# Execute the command passed to the container
exec "$@"