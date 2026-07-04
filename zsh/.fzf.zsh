# Setup fzf — portable across macOS (brew), Arch, and Debian/Ubuntu
# ---------
# Add Homebrew's fzf to PATH on macOS if present
if [[ -d /opt/homebrew/opt/fzf/bin ]] && [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi

if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    # fzf >= 0.48 (brew, Arch, recent static builds): single-command integration
    source <(fzf --zsh)
  else
    # Older fzf (e.g. Debian/Ubuntu apt 0.44): source distro-provided files
    for _fzf_dir in \
      /usr/share/fzf \
      /usr/share/doc/fzf/examples \
      /usr/share/zsh/site-functions \
      /usr/local/opt/fzf/shell; do
      [[ -f "$_fzf_dir/key-bindings.zsh" ]] && source "$_fzf_dir/key-bindings.zsh"
      [[ -f "$_fzf_dir/completion.zsh"   ]] && source "$_fzf_dir/completion.zsh"
    done
    unset _fzf_dir
  fi
fi
