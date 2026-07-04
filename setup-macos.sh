#!/usr/bin/env bash
#
# macOS bootstrap for these dotfiles.
#   1. Installs Homebrew (if missing)
#   2. Installs everything in brew/Brewfile (stow, bitwarden-cli, apps, ...)
#   3. Stows the config packages into $HOME
#   4. Pulls secrets (.env) down from Bitwarden and installs them
#
# Usage:
#   ./setup-macos.sh                 # full run
#   ./setup-macos.sh --skip-secrets  # skip the Bitwarden step
#   ./setup-macos.sh --skip-brew     # skip Homebrew + brew bundle
#
# Linux? Use setup-arch-omarchy.sh instead.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info()    { printf '\033[0;34m[INFO]\033[0m %s\n' "$*"; }
log_success() { printf '\033[0;32m[ OK ]\033[0m %s\n' "$*"; }
log_warning() { printf '\033[0;33m[WARN]\033[0m %s\n' "$*"; }
log_error()   { printf '\033[0;31m[ERR ]\033[0m %s\n' "$*" >&2; }

SKIP_SECRETS=false
SKIP_BREW=false
for arg in "$@"; do
  case "$arg" in
    --skip-secrets) SKIP_SECRETS=true ;;
    --skip-brew)    SKIP_BREW=true ;;
    *) log_error "Unknown option: $arg"; exit 1 ;;
  esac
done

# ── 0. Sanity ────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  log_error "This is the macOS setup. On Linux run ./setup-arch-omarchy.sh"
  exit 1
fi

# ── 1 & 2. Homebrew + Brewfile ───────────────────────────────────────
if [[ "$SKIP_BREW" == false ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Put brew on PATH for this script (Apple Silicon default)
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

  log_info "Installing packages from Brewfile (this can take a while)..."
  brew bundle --file="$DOTFILES_DIR/brew/Brewfile" || log_warning "brew bundle reported issues (continuing)"
  log_success "Homebrew packages installed"
else
  log_info "Skipping Homebrew (--skip-brew)"
fi

# ── 3. Stow config packages ──────────────────────────────────────────
log_info "Stowing dotfiles..."
command -v stow >/dev/null 2>&1 || { log_error "stow not found — run without --skip-brew, or 'brew install stow'"; exit 1; }

# macOS-relevant packages. hermes/claude are guarded below (need their target dir).
STOW_PACKAGES=(zsh bash git gh nvim ghostty iterm karabiner aerospace bin fonts wallpapers claude hermes)

cd "$DOTFILES_DIR"
for pkg in "${STOW_PACKAGES[@]}"; do
  [[ -d "$pkg" ]] || continue
  # Guard: only stow into ~/.claude and ~/.hermes if they already exist as real
  # dirs — otherwise stow would symlink the whole directory (clobbering state).
  case "$pkg" in
    claude) [[ -d "$HOME/.claude" ]] || { log_warning "skip 'claude' (install Claude Code first)"; continue; } ;;
    hermes) [[ -d "$HOME/.hermes" ]] || { log_warning "skip 'hermes' (install Hermes first)"; continue; } ;;
  esac
  if stow -R "$pkg" 2>/dev/null; then
    log_success "stowed $pkg"
  else
    log_warning "stow $pkg had conflicts — resolve the offending files and re-run"
  fi
done

# ── 4. Secrets from Bitwarden ────────────────────────────────────────
if [[ "$SKIP_SECRETS" == true ]]; then
  log_info "Skipping Bitwarden secrets (--skip-secrets)"
elif ! command -v bw >/dev/null 2>&1; then
  log_warning "bw not installed — skipping secrets (see SECRETS.md)"
else
  log_info "Pulling .env secrets from Bitwarden (see env-sync.manifest) ..."
  # Loads BW_CLIENTID/BW_CLIENTSECRET/BW_PASSWORD from Keychain if you set them.
  [[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc" 2>/dev/null || true

  if [[ -z "${BW_CLIENTID:-}" ]] && ! bw login --check >/dev/null 2>&1; then
    log_info "Not logged in and no API key in Keychain. Logging in interactively:"
    bw login || log_warning "bw login skipped"
  fi

  "$DOTFILES_DIR/bin/.local/bin/env-sync.sh" pull \
    && log_success "all manifest .env files installed" \
    || log_warning "secret pull skipped/failed (see SECRETS.md)"
fi

log_success "macOS setup complete."
echo
log_info "Next steps you may want:"
echo "   • bash apple/setup.sh          # macOS defaults (review first)"
echo "   • gh auth login                # GitHub CLI auth"
echo "   • see SECRETS.md               # remaining API keys / Bitwarden setup"
