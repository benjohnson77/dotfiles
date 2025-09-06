# ============================================================================
# Bash Profile - Login Shell Configuration
# This file is executed for login shells
# ============================================================================

# Source .bashrc if it exists (for interactive shells)
if [[ -f ~/.bashrc ]]; then
    source ~/.bashrc
fi

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

# Default editor (fallback chain)
if command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
    export VISUAL="nvim"
elif command -v vim >/dev/null 2>&1; then
    export EDITOR="vim"
    export VISUAL="vim"
else
    export EDITOR="nano"
    export VISUAL="nano"
fi

# Pager settings
export PAGER="less"
export LESS="-R -i -M -S -x4"

# Language settings
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# History settings (login shells)
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
export HISTCONTROL="ignoreboth:erasedups"

# ============================================================================
# PATH CONFIGURATION
# ============================================================================

# Function to safely add to PATH
add_to_path() {
    if [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]]; then
        if [[ "$2" == "prepend" ]]; then
            export PATH="$1:$PATH"
        else
            export PATH="$PATH:$1"
        fi
    fi
}

# Add common local directories to PATH
add_to_path "$HOME/bin" prepend
add_to_path "$HOME/.local/bin" prepend

# macOS specific paths
if [[ "$(uname)" == "Darwin" ]]; then
    add_to_path "/opt/homebrew/bin" prepend
    add_to_path "/opt/homebrew/sbin" prepend
    add_to_path "/usr/local/bin" prepend
    add_to_path "/usr/local/sbin" prepend
fi

# ============================================================================
# DEVELOPMENT ENVIRONMENT SETUP
# ============================================================================

# Ruby environment (rbenv)
if command -v rbenv >/dev/null 2>&1; then
    eval "$(rbenv init -)"
fi

# Node.js environment (if nvm is installed)
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"
    # Load nvm bash_completion if available
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
fi

# Python environment (pyenv)
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    add_to_path "$PYENV_ROOT/bin" prepend
    eval "$(pyenv init -)"
fi

# Go environment
if command -v go >/dev/null 2>&1; then
    export GOPATH="$HOME/go"
    add_to_path "$GOPATH/bin"
fi

# Rust environment
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

# ============================================================================
# TOOL-SPECIFIC CONFIGURATIONS
# ============================================================================

# Terraform completion
if command -v terraform >/dev/null 2>&1; then
    complete -C "$(which terraform)" terraform
fi

# Docker completion (macOS)
if [[ "$(uname)" == "Darwin" ]] && [[ -f "/Applications/Docker.app/Contents/Resources/etc/docker.bash-completion" ]]; then
    source "/Applications/Docker.app/Contents/Resources/etc/docker.bash-completion"
    source "/Applications/Docker.app/Contents/Resources/etc/docker-compose.bash-completion"
fi

# kubectl completion
if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion bash)
fi

# AWS CLI completion
if command -v aws_completer >/dev/null 2>&1; then
    complete -C "$(which aws_completer)" aws
fi

# ============================================================================
# MACHINE-SPECIFIC CONFIGURATIONS (existing)
# ============================================================================

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/benjohnson/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# RVM (Ruby Version Manager)
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# ============================================================================
# WELCOME MESSAGE (for login shells)
# ============================================================================

# Show a brief system info on login (only for interactive shells)
if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -z "$SSH_TTY" ]]; then
    echo "Welcome to $(hostname)!"
    echo "Today is $(date '+%A, %B %d, %Y at %H:%M')"
    if command -v uptime >/dev/null 2>&1; then
        echo "System uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
    fi
    echo
fi
