#!/bin/bash

# Sync Ruby version from .tool-versions to .devcontainer/.env
sync_ruby_version() {
    local script_path=".devcontainer/sync-ruby-version.sh"
    if [ -f "$script_path" ]; then
        echo "Syncing Ruby version from .tool-versions..."
        bash "$script_path"
    else
        echo "Warning: $script_path not found, skipping Ruby version sync"
    fi
}

# devcontainerを起動する関数
up_devcontainer() {
    local additional_flags="$1"
    
    # Sync Ruby version before starting devcontainer
    sync_ruby_version
    
    # Get the tmux config path
    tmux_config_path=~/.config/tmux
    tmux_resolved_config_path=$(readlink -f "$tmux_config_path")
    echo "Resolved config path: $tmux_resolved_config_path"
    
    # Construct the command to run the devcontainer
    command="devcontainer up $additional_flags"
    
    # Add mount options
    command+=" --mount type=bind,source=$tmux_resolved_config_path,target=/home/vscode/.config/tmux"
    
    # Add additional features
    command+=" --additional-features='{ \
            \"ghcr.io/duduribeiro/devcontainer-features/tmux:1\": {} \
        }'"
    
    # Add workspace folder
    command+=" --workspace-folder ."
    
    eval "$command"
}

# devcontainerに接続する関数
exec_devcontainer() {
    # Prepare exec command with environment variables
    exec_command="devcontainer exec"
    exec_command+=" --workspace-folder . /bin/bash"
    
    eval "$exec_command"
}