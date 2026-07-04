#!/bin/bash

# =============================================================================
# Debian / Ubuntu Dotfiles Setup Script
# =============================================================================
# Mirrors setup-arch-omarchy.sh but targets Debian/Ubuntu (apt) and works on
# headless servers (no desktop/GUI packages). Uses GNU Stow for dotfiles.
#
# What apt does NOT provide (installed manually here):
#   - oh-my-zsh          (installed from upstream installer)
#   - powerlevel10k      (git clone into oh-my-zsh custom themes)
#   - modern fzf         (apt ships 0.44; we install a current static build so
#                         `fzf --zsh` works — .fzf.zsh falls back gracefully if
#                         only old apt fzf is present)
#
# Author: bjohnson
# =============================================================================

set -e

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_REPO="https://github.com/benjohnson77/dotfiles.git"

# CLI-only stow packages (skip desktop/GUI: hypr, waybar, aerospace, etc.)
STOW_PACKAGES=(zsh git gh nvim fonts bash)

check_debian() {
    if [[ ! -f /etc/debian_version ]]; then
        log_error "This script is for Debian/Ubuntu (apt) systems only!"
        exit 1
    fi
    log_success "Debian/Ubuntu detected ($(. /etc/os-release && echo "$PRETTY_NAME"))"
}

update_system() {
    log_info "Updating apt package lists..."
    sudo apt-get update -qq
    log_success "Package lists updated"
}

install_packages() {
    log_info "Installing base packages via apt..."
    local packages=(
        stow          # dotfiles management
        zsh           # shell
        git           # vcs
        neovim        # editor
        curl wget     # downloads
        fzf           # fuzzy finder (old on apt; upgraded below)
        gh            # github cli (available on recent Ubuntu; may be absent on old Debian)
        fontconfig    # fc-cache for fonts
    )
    for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            log_info "$pkg already installed"
        else
            sudo apt-get install -y "$pkg" 2>/dev/null \
                && log_success "installed $pkg" \
                || log_warning "could not install $pkg via apt (may need another source)"
        fi
    done
}

install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "oh-my-zsh already present"
    else
        log_info "Installing oh-my-zsh..."
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        log_success "oh-my-zsh installed"
    fi
}

install_powerlevel10k() {
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ -d "$p10k_dir" ]]; then
        log_info "powerlevel10k already present"
    else
        log_info "Installing powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
        log_success "powerlevel10k installed"
    fi
}

# apt fzf is old (0.44) and lacks `fzf --zsh`. Install a current static build
# into ~/.local/bin so integration is first-class. .fzf.zsh still works either
# way, but this gives the nicer one-shot integration.
install_modern_fzf() {
    if command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
        log_info "fzf already supports --zsh ($(fzf --version)); skipping upgrade"
        return
    fi
    log_info "Installing a modern fzf into ~/.local/bin..."
    local arch tag url tmp
    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        armv7l) arch="armv7" ;;
        *) log_warning "unknown arch $(uname -m); skipping fzf upgrade"; return ;;
    esac
    tag=$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest \
          | grep -oP '"tag_name":\s*"v\K[^"]+') || { log_warning "could not query fzf release"; return; }
    url="https://github.com/junegunn/fzf/releases/download/v${tag}/fzf-${tag}-linux_${arch}.tar.gz"
    tmp=$(mktemp -d)
    if curl -fsSL "$url" -o "$tmp/fzf.tar.gz"; then
        mkdir -p "$HOME/.local/bin"
        tar xzf "$tmp/fzf.tar.gz" -C "$HOME/.local/bin" fzf
        chmod +x "$HOME/.local/bin/fzf"
        log_success "fzf ${tag} installed to ~/.local/bin (ensure it is on PATH)"
    else
        log_warning "fzf download failed; apt fzf will be used with fallback integration"
    fi
    rm -rf "$tmp"
}

setup_dotfiles() {
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        log_info "Dotfiles present at $DOTFILES_DIR; pulling latest"
        git -C "$DOTFILES_DIR" pull --ff-only || log_warning "git pull failed (local changes?)"
    else
        log_info "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
    log_success "Dotfiles ready at $DOTFILES_DIR"
}

stow_dotfiles() {
    log_info "Stowing dotfiles with GNU Stow..."
    cd "$DOTFILES_DIR"
    local ts; ts="$(date +%Y%m%d-%H%M%S)"
    for package in "${STOW_PACKAGES[@]}"; do
        [[ -d "$package" ]] || { log_info "skip $package (not in repo)"; continue; }
        # Back up any real (non-symlink) file that stow would need to create.
        # Walk the package's tracked files; the target is the same relative path
        # under $HOME. A REAL file there blocks stow, so move it aside first.
        while IFS= read -r -d '' src; do
            local rel="${src#"$package"/}"
            local abs="$HOME/$rel"
            if [[ -e "$abs" && ! -L "$abs" ]]; then
                mkdir -p "$(dirname "$abs")"
                mv "$abs" "$abs.bak-$ts"
                log_warning "backed up existing $abs -> $abs.bak-$ts"
            fi
        done < <(find "$package" -type f -print0)
        if stow -R "$package" 2>/dev/null; then
            log_success "stowed $package"
        else
            log_warning "failed to stow $package (conflicts may remain)"
        fi
    done
}

set_default_shell() {
    local zsh_path; zsh_path="$(command -v zsh)"
    if [[ -z "$zsh_path" ]]; then log_warning "zsh not found; skipping chsh"; return; fi
    grep -qxF "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]]; then
        log_info "Setting default shell to zsh..."
        sudo usermod -s "$zsh_path" "$USER" \
            && log_success "default shell set to $zsh_path (effective on next login)" \
            || log_warning "could not change shell; run: chsh -s $zsh_path"
    else
        log_info "default shell already zsh"
    fi
}

refresh_fonts() {
    if command -v fc-cache >/dev/null 2>&1; then
        log_info "Refreshing font cache..."
        fc-cache -f >/dev/null 2>&1 || true
        log_success "Font cache refreshed"
    fi
}

show_post_install_info() {
    log_success "=== Debian/Ubuntu setup complete ==="
    echo
    log_info "Next steps:"
    echo "  1. Start zsh now:            exec zsh"
    echo "  2. Configure p10k (optional): p10k configure"
    echo "  3. Ensure ~/.local/bin is on PATH (for the modern fzf)"
    echo
    log_info "Dotfiles managed with GNU Stow from: $DOTFILES_DIR"
    echo "  - Add config:    stow <package>   (from $DOTFILES_DIR)"
    echo "  - Remove config: stow -D <package>"
    echo "  - Restow:        stow -R <package>"
}

main() {
    log_info "Starting Debian/Ubuntu dotfiles setup..."
    echo
    check_debian
    update_system
    install_packages
    install_oh_my_zsh
    install_powerlevel10k
    install_modern_fzf
    setup_dotfiles
    stow_dotfiles
    set_default_shell
    refresh_fonts
    show_post_install_info
}

main "$@"
