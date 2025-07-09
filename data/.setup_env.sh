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

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/root/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/root/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/root/miniconda3/etc/profile.d/conda.sh"
    else
        env_load PATH "/root/miniconda3/bin"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export CUDA_HOME="/usr/local/cuda"
alias LOAD_CUDA="env_load PATH $CUDA_HOME/bin && env_load LD_LIBRARY_PATH $CUDA_HOME/lib64"
alias UNLOAD_CUDA="env_unload PATH $CUDA_HOME/bin && env_unload LD_LIBRARY_PATH $CUDA_HOME/lib64"
# Load CUDA by default
LOAD_CUDA

export VCPKG_HOME="/usr/local/vcpkg"
export VCPKG_ROOT=$VCPKG_HOME
alias LOAD_VCPKG="env_load PATH $VCPKG_HOME"
alias UNLOAD_VCPKG="env_unload PATH $VCPKG_HOME"
alias VCPKG_UPDATE="pushd $VCPKG_HOME && git pull && popd"
# Load vcpkg by default
LOAD_VCPKG