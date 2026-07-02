# Dotfiles

Personal configuration for macOS (primary) and Arch/Omarchy Linux. Managed with
[GNU Stow](https://www.gnu.org/software/stow/): each top-level directory is a
"package" whose contents are symlinked into `$HOME`, mirroring the layout the
files should have relative to your home directory.

For example, `stow zsh` creates `~/.zshrc → ~/.dotfiles/zsh/.zshrc`, and
`stow nvim` creates `~/.config/nvim → ~/.dotfiles/nvim/.config/nvim`.

---

## Quick start (new macOS machine)

```bash
# 1. Install Homebrew (grab the current one-liner from https://brew.sh)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Put brew on PATH (Apple Silicon) and reload the shell
echo 'export PATH=/opt/homebrew/bin:$PATH' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. Clone this repo to ~/.dotfiles
git clone <this-repo-url> ~/.dotfiles
cd ~/.dotfiles

# 4. Install all apps & tools
brew bundle --file=~/.dotfiles/brew/Brewfile

# 5. Symlink the configs you want (see "Stow packages" below)
stow zsh git nvim gh ghostty iterm karabiner aerospace sketchybar raycast

# 6. Authenticate GitHub CLI (regenerates the gitignored gh/hosts.yml)
gh auth login

# 7. Apply macOS system tweaks (review the file first)
bash apple/setup.sh
```

> **Note:** `stow` itself is installed by step 4 (it's in the Brewfile), so run
> the brew bundle before stowing.

---

## Quick start (Arch / Omarchy Linux)

An automated bootstrap script handles packages, Stow, SSH keys, and theming:

```bash
git clone <this-repo-url> ~/.dotfiles
cd ~/.dotfiles
./setup-arch-omarchy.sh
```

The setup assumes a base [Omarchy](https://omarchy.org/) install (which already
ships Hyprland, Waybar, Neovim, etc.). The script:

1. Runs `pacman -Syu`, then installs a small set of extras Omarchy doesn't
   include: `stow`, `bolt`, `github-cli`, `ghostty`, and the
   `zsh-theme-powerlevel10k-git` AUR package.
2. Stows the Linux-relevant packages (`zsh`, `git`, `nvim`, `fonts`, `waybar`,
   `fish`, `ghostty`, `hypr`).
3. Generates an ed25519 SSH key if one doesn't exist.
4. Sets up the Omarchy theme and wallpapers.

> **`pacman/pacFile`** is a full snapshot of installed packages kept for
> reference only — the setup script does **not** install from it. To refresh the
> snapshot on the Arch machine, dump the explicitly-installed packages:
>
> ```bash
> pacman -Qqe > ~/.dotfiles/pacman/pacFile
> ```
>
> (`-Qqe` lists only packages you chose, not their dependencies — much cleaner
> than the current full dump.)

---

## Stow packages

| Package      | Symlinks to                         | What it is                                    |
|--------------|-------------------------------------|-----------------------------------------------|
| `zsh`        | `~/.zshrc`, `~/.p10k.zsh`           | Zsh + Powerlevel10k prompt config             |
| `bash`       | `~/.bashrc`, `~/.bash_profile`      | Bash fallback config                          |
| `fish`       | `~/.config/fish/`                   | Fish shell config                             |
| `git`        | `~/.gitconfig`, `~/.gitignore`      | Git aliases, user, gh credential helper       |
| `gh`         | `~/.config/gh/`                     | GitHub CLI config (**tokens are gitignored**) |
| `nvim`       | `~/.config/nvim/`                   | Neovim (LazyVim) config                        |
| `ghostty`    | `~/.config/ghostty/`                | Ghostty terminal config                       |
| `iterm`      | (manual import — see below)         | iTerm2 prefs & color schemes                  |
| `karabiner`  | `~/.config/karabiner/`              | Karabiner-Elements key remapping              |
| `aerospace`  | `~/.config/aerospace/`              | AeroSpace tiling window manager (macOS)       |
| `sketchybar` | `~/.config/sketchybar/`             | SketchyBar menu bar (macOS)                   |
| `raycast`    | `~/.config/raycast/`                | Raycast extensions & scripts                  |
| `hypr`       | `~/.config/hypr/`                   | Hyprland compositor (Linux)                   |
| `waybar`     | `~/.config/waybar/`                 | Waybar status bar (Linux)                     |
| `fonts`      | `~/.fonts` / `~/.local/share/fonts` | Powerline / Nerd Font files                   |
| `wallpapers` | wallpaper images                    | Desktop wallpapers                            |

Non-Stow helper directories: `brew/` (Homebrew manifest), `apple/` (macOS
`defaults` tweaks), `pacman/` (Arch package list).

### Common Stow commands

```bash
stow <package>       # symlink a package into $HOME
stow -D <package>    # remove (unstow) a package's symlinks
stow -R <package>    # restow (unstow then stow) after adding/renaming files
stow -n -v <package> # dry run — show what would happen without doing it
```

If Stow reports a conflict, it means a real (non-symlink) file already exists at
the target. Move or delete it, then re-run `stow`.

---

## Homebrew management

`brew/Brewfile` is the single source of truth for installed formulae, casks, and
taps. It lists only packages installed *on request* so it stays readable.

```bash
# Install / update everything in the Brewfile
brew bundle --file=~/.dotfiles/brew/Brewfile

# See what's missing or outdated
brew bundle check --file=~/.dotfiles/brew/Brewfile

# Regenerate the Brewfile from what's currently installed
brew bundle dump --file=~/.dotfiles/brew/Brewfile --force

# Uninstall anything NOT listed in the Brewfile (destructive — review first)
brew bundle cleanup --file=~/.dotfiles/brew/Brewfile
```

After installing or removing brew packages, run `brew bundle dump ... --force` and
commit the updated `Brewfile` to keep it in sync.

---

## Neovim plugins

This config uses [LazyVim](https://www.lazyvim.org/). Plugins install
automatically on first launch. To sync manually:

```vim
:Lazy sync
```

---

## iTerm2 (macOS)

Preferences and color schemes aren't symlinked — import them once:

```bash
# Import the full preferences plist
defaults import com.googlecode.iterm2 ~/.dotfiles/iterm/com.googlecode.iterm2.plist

# Export again after changing settings, to update the repo
defaults export com.googlecode.iterm2 ~/.dotfiles/iterm/com.googlecode.iterm2.plist
```

Color schemes (`ben.itermcolors`, `Snazzy.itermcolors`): import via
**iTerm2 → Settings → Profiles → Colors → Color Presets → Import**.

---

## macOS system tweaks

`apple/setup.sh` applies opinionated `defaults` settings (faster key repeat,
Finder/Dock behavior, etc.). Review it before running — the most aggressive
options are commented out.

Handy one-off: show only active apps in the Dock:

```bash
defaults write com.apple.dock static-only -bool TRUE && killall Dock
```

---

## Secrets

- **GitHub tokens** live in `gh/.config/gh/hosts.yml`, which is **gitignored and
  never committed**. Regenerate it on a new machine with `gh auth login`.
- No credentials, API keys, or private keys are stored in this repo. If you add a
  tool that writes secrets into a config file, add that file to `.gitignore`
  first.
