# @ https://patorjk.com/software/taag/?p=display&f=Varsity&t=JNL%2FDL&x=none
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

echo "[ENV-SETUP] Sourcing \${ENV_SETUP_FILE}: ${ENV_SETUP_FILE}"

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

if [ -d "${UV_HOME:-}" ]; then
    alias LOAD_UV="env_load PATH $UV_HOME"
    alias UNLOAD_UV="env_unload PATH $UV_HOME"
    env_load PATH "$UV_HOME"
    echo "[ENV-SETUP] UV initialized from $UV_HOME"
    cat << 'EOF'
|- NOTE: For managing shared UV cache and python directory:
|-   1. Export UV_CACHE_DIR and UV_PYTHON_INSTALL_DIR to a target directory. 
|       (No need to create them first.)
|-   2. Run command below ONLY ONCE to create the shared directories: 
|       $ create-shared-dir <group> ${UV_CACHE_DIR} ${UV_PYTHON_INSTALL_DIR}
|-   3. For all users in <group>, make sure UV_CACHE_DIR and 
|       UV_PYTHON_INSTALL_DIR are exported properly.
|       You can do this in ${ENV_SETUP_FILE} for convenience.
|-   4. Remove this NOTE from ${ENV_SETUP_FILE} if you want.
EOF
    ## You can uncomment the following line to set a shared cache dir for UV.
    ## Make sure to run `sudo create-shared-dir <group> $UV_CACHE_DIR` ONLY ONCE.
    # export UV_CACHE_DIR="$UV_HOME/.cache"
    # export UV_PYTHON_INSTALL_DIR="$UV_HOME/python"
    echo "|-          UV_CACHE_DIR: ${UV_CACHE_DIR:-<not set>}"
    echo "|-          UV_PYTHON_INSTALL_DIR: ${UV_PYTHON_INSTALL_DIR:-<not set>}"
else
    unset UV_HOME
fi