# ============================================================================
# Enhanced Bash Configuration
# Works on both local macOS and remote Linux servers
# ============================================================================

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ============================================================================
# HISTORY CONFIGURATION
# ============================================================================
# Don't put duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth

# Append to the history file, don't overwrite it
shopt -s histappend

# Set history length
HISTSIZE=10000
HISTFILESIZE=20000

# Check the window size after each command and update LINES and COLUMNS
shopt -s checkwinsize

# ============================================================================
# COLORS AND PROMPT
# ============================================================================
# Enable color support
if [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Enhanced prompt with git support
__git_ps1_wrapper() {
    if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch=$(git branch 2>/dev/null | grep '^*' | colrm 1 2)
        if [[ -n "$branch" ]]; then
            local status=$(git status --porcelain 2>/dev/null)
            if [[ -n "$status" ]]; then
                echo " (${branch}*)"
            else
                echo " (${branch})"
            fi
        fi
    fi
}

# Set colorful prompt
if [[ "$EUID" -eq 0 ]]; then
    # Root prompt (red)
    PS1="\[${RED}\]\u@\h\[${NC}\]:\[${BLUE}\]\w\[${YELLOW}\]\$(__git_ps1_wrapper)\[${RED}\]# \[${NC}\]"
else
    # Regular user prompt (green)
    PS1="\[${GREEN}\]\u@\h\[${NC}\]:\[${BLUE}\]\w\[${YELLOW}\]\$(__git_ps1_wrapper)\[${GREEN}\]$ \[${NC}\]"
fi

# ============================================================================
# ALIASES - NAVIGATION AND BASIC COMMANDS
# ============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# ls aliases with colors
alias ls='ls --color=auto 2>/dev/null || ls -G 2>/dev/null || ls'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -altr'  # Sort by time, newest last
alias lh='ls -alh'   # Human readable sizes

# grep with color
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ============================================================================
# ALIASES - SYSTEM INFORMATION
# ============================================================================
alias h='history'
alias j='jobs -l'
alias df='df -h'
alias du='du -h'
alias free='free -h 2>/dev/null || vm_stat'
alias ps='ps aux'
alias top='top -o cpu'

# Network aliases
alias ports='netstat -tulanp 2>/dev/null || netstat -tuln'
alias myip='curl -s http://checkip.amazonaws.com/ || curl -s http://ipecho.net/plain; echo'
alias localip='hostname -I 2>/dev/null | cut -d" " -f1 || ifconfig | grep "inet " | grep -v 127.0.0.1 | cut -d" " -f2'

# Process management
alias psg='ps aux | grep -i'
alias killall='killall -v'

# ============================================================================
# ALIASES - DEVELOPMENT
# ============================================================================
# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Docker shortcuts (if docker is available)
if command -v docker >/dev/null 2>&1; then
    alias dk='docker'
    alias dkps='docker ps'
    alias dkpa='docker ps -a'
    alias dki='docker images'
    alias dkc='docker-compose'
fi

# Kubernetes shortcuts (if kubectl is available)
if command -v kubectl >/dev/null 2>&1; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    alias kgn='kubectl get nodes'
fi

# ============================================================================
# USEFUL FUNCTIONS
# ============================================================================

# Create directory and cd into it
mkdir_cd() {
    mkdir -p "$1" && cd "$1"
}
alias mkcd='mkdir_cd'

# Extract various archive formats
extract() {
    if [[ -f $1 ]]; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find file by name
ff() {
    find . -name "*$1*" 2>/dev/null
}

# Find and grep
fg() {
    find . -type f -exec grep -l "$1" {} \; 2>/dev/null
}

# Show PATH in readable format
path() {
    echo $PATH | tr ':' '\n' | nl
}

# Show disk usage of current directory
duh() {
    du -h --max-depth=1 2>/dev/null | sort -hr || du -h -d 1 | sort -hr
}

# Quick backup of a file
bak() {
    cp "$1"{,.bak}
}

# Show running processes listening on a specific port
whoport() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: whoport <port_number>"
        return 1
    fi
    local port=$1
    if command -v lsof >/dev/null 2>&1; then
        lsof -i :"$port"
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln | grep ":$port "
    else
        echo "Neither lsof nor netstat available"
    fi
}

# System update function (works on different distros)
sysupdate() {
    if [[ -f /etc/redhat-release ]]; then
        sudo yum update -y
    elif [[ -f /etc/debian_version ]]; then
        sudo apt update && sudo apt upgrade -y
    elif [[ -f /etc/arch-release ]]; then
        sudo pacman -Syu
    elif [[ "$(uname)" == "Darwin" ]]; then
        if command -v brew >/dev/null 2>&1; then
            brew update && brew upgrade
        fi
    else
        echo "Unsupported distribution"
    fi
}

# Weather function
weather() {
    local city=${1:-}
    curl -s "wttr.in/${city}?format=3"
}

# ============================================================================
# SERVER ADMINISTRATION HELPERS
# ============================================================================

# Show system information
sysinfo() {
    echo "System Information:"
    echo "=================="
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime)"
    echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory:"
    if command -v free >/dev/null 2>&1; then
        free -h
    elif [[ "$(uname)" == "Darwin" ]]; then
        vm_stat
    fi
    echo "Disk Space:"
    df -h
}

# Find large files
bigfiles() {
    find . -type f -exec ls -lh {} \; 2>/dev/null | awk '{print $5 " " $9}' | sort -hr | head -20
}

# Show directory sizes
dirsize() {
    du -sh */ 2>/dev/null | sort -hr
}

# Tail log files with color highlighting
taillog() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: taillog <logfile>"
        return 1
    fi
    tail -f "$1" | sed -e 's/ERROR/\o033[31mERROR\o033[39m/g' -e 's/WARN/\o033[33mWARN\o033[39m/g' -e 's/INFO/\o033[32mINFO\o033[39m/g'
}

# ============================================================================
# COMPLETION AND EXTRAS
# ============================================================================

# Enable programmable completion features
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        . /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        . /etc/bash_completion
    elif [[ -f /opt/homebrew/etc/bash_completion ]]; then
        . /opt/homebrew/etc/bash_completion
    elif [[ -f /usr/local/etc/bash_completion ]]; then
        . /usr/local/etc/bash_completion
    fi
fi

# ============================================================================
# MACHINE-SPECIFIC CONFIGURATIONS (keep existing)
# ============================================================================
### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/benjohnson/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
