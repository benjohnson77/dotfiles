#!/bin/bash

# =============================================================================
# Arch Linux Post-Omarchy Installation Setup Script (Lean Version)
# =============================================================================
# This script only adds what omarchy doesn't already provide.
# Omarchy already includes: hyprland, waybar, yay, most fonts, basic theming
# Uses GNU Stow for dotfiles management
#
# Author: bjohnson
# Created: $(date +"%Y-%m-%d")
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="$HOME/dotfiles"
DOTFILES_REPO="https://github.com/benjohnson77/dotfiles.git"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Arch Linux
check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        log_error "This script is designed for Arch Linux only!"
        exit 1
    fi
    log_success "Arch Linux detected"
}

# Check if omarchy is installed
check_omarchy() {
    if ! pacman -Q omarchy-chromium &>/dev/null; then
        log_error "Omarchy doesn't appear to be installed. Install omarchy first!"
        exit 1
    fi
    log_success "Omarchy installation detected"
}

# Update system packages
update_system() {
    log_info "Updating system packages..."
    sudo pacman -Syu --noconfirm
    log_success "System updated"
}

# Install only packages that omarchy likely doesn't include
install_missing_packages() {
    log_info "Installing packages not included in omarchy..."
    
    local packages=(
        # Essential for dotfiles management
        "stow"
        
        # Development tools that might not be in omarchy
        "github-cli"
        "lazygit"
        
        # Shell theme (AUR package)
        "zsh-theme-powerlevel10k-git"
    )
    
    for package in "${packages[@]}"; do
        if pacman -Q "$package" &>/dev/null; then
            log_info "$package already installed"
        else
            log_info "Installing $package..."
            if [[ "$package" == *"-git" ]]; then
                yay -S --noconfirm "$package" || log_warning "Failed to install $package"
            else
                sudo pacman -S --noconfirm "$package" || log_warning "Failed to install $package"
            fi
        fi
    done
    
    log_success "Additional packages installed"
}

# Clone and setup dotfiles
setup_dotfiles() {
    if [[ -d "$DOTFILES_DIR" ]]; then
        log_info "Dotfiles directory already exists at $DOTFILES_DIR"
        cd "$DOTFILES_DIR"
        git pull origin main
    else
        log_info "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        cd "$DOTFILES_DIR"
    fi
    
    log_success "Dotfiles ready at $DOTFILES_DIR"
}

# Use GNU Stow to manage dotfiles
stow_dotfiles() {
    log_info "Using GNU Stow to manage dotfiles..."
    
    cd "$DOTFILES_DIR"
    
    # Auto-detect stow packages (directories that contain config files)
    local stow_packages=()
    
    # Common dotfile directories to check
    local potential_packages=(
        "zsh"
        "git"
        "nvim"
        "fonts"
        "waybar"
        "fish"
        "ghostty"
        "hypr"
    )
    
    for package in "${potential_packages[@]}"; do
        if [[ -d "$package" ]]; then
            stow_packages+=("$package")
        fi
    done
    
    if [[ ${#stow_packages[@]} -eq 0 ]]; then
        log_warning "No stow packages found in $DOTFILES_DIR"
        return
    fi
    
    for package in "${stow_packages[@]}"; do
        log_info "Stowing $package..."
        # Unstow first in case there are existing files, ignore errors
        stow -D "$package" 2>/dev/null || true
        # Then stow
        if stow "$package" 2>/dev/null; then
            log_success "$package stowed"
        else
            log_warning "Failed to stow $package (conflicts may exist)"
        fi
    done
    
    log_success "Dotfiles management with GNU Stow completed"
}

# Setup omarchy theme and wallpapers
setup_omarchy_theme() {
    log_info "Setting up omarchy solarized theme..."
    
    # Check if solarized theme exists
    local solarized_theme="$HOME/.config/omarchy/themes/solarized"
    if [[ -d "$solarized_theme" ]]; then
        # Set solarized as current theme
        ln -sf "$solarized_theme" "$HOME/.config/omarchy/current/theme"
        log_info "Solarized theme activated"
        
        # Copy wallpapers if they exist in dotfiles
        local wallpapers_dir="$DOTFILES_DIR/wallpapers/solarized"
        if [[ -d "$wallpapers_dir" ]]; then
            mkdir -p "$solarized_theme/backgrounds"
            cp -r "$wallpapers_dir/"* "$solarized_theme/backgrounds/" 2>/dev/null || true
            log_info "Wallpapers copied to theme directory"
        fi
    else
        log_warning "Solarized theme not found in omarchy themes"
    fi
    
    log_success "Omarchy theme setup completed"
}

# Generate SSH key if it doesn't exist
setup_ssh() {
    log_info "Setting up SSH key..."
    
    if [[ ! -f "$HOME/.ssh/id_rsa" ]] && [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$HOME/.ssh/id_ed25519" -N ""
        
        # Set proper permissions
        chmod 700 "$HOME/.ssh"
        chmod 600 "$HOME/.ssh/id_ed25519"
        chmod 644 "$HOME/.ssh/id_ed25519.pub"
        
        log_success "SSH key generated: $HOME/.ssh/id_ed25519.pub"
        log_info "Add this key to your GitHub account:"
        echo "----------------------------------------"
        cat "$HOME/.ssh/id_ed25519.pub"
        echo "----------------------------------------"
    else
        log_info "SSH key already exists"
    fi
}

# Create useful directories
create_directories() {
    log_info "Creating useful directories..."
    
    mkdir -p "$HOME/Projects" \
             "$HOME/Scripts" \
             "$HOME/.local/bin"
    
    log_success "Directories created"
}

# Refresh font cache (omarchy should have fonts, but refresh cache)
refresh_fonts() {
    log_info "Refreshing font cache..."
    fc-cache -fv > /dev/null 2>&1
    log_success "Font cache refreshed"
}

# Display post-installation instructions
show_post_install_info() {
    log_success "=== Setup completed successfully! ==="
    echo
    log_info "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. If you generated an SSH key, add it to your GitHub account"
    echo "  3. Configure git if not done already:"
    echo "     git config --global user.name \"Your Name\""
    echo "     git config --global user.email \"your.email@example.com\""
    echo
    log_info "Dotfiles are managed with GNU Stow from: $DOTFILES_DIR"
    log_info "To manage dotfiles:"
    echo "  - Add new config: stow <package-name> (from $DOTFILES_DIR)"
    echo "  - Remove config: stow -D <package-name>"
    echo "  - Restow config: stow -R <package-name>"
    echo
}

# Main execution
main() {
    log_info "Starting lean Arch Linux post-omarchy setup..."
    echo
    
    check_arch
    check_omarchy
    update_system
    install_missing_packages
    setup_dotfiles
    stow_dotfiles
    setup_omarchy_theme
    setup_ssh
    create_directories
    refresh_fonts
    
    show_post_install_info
}

# Run main function
main "$@"