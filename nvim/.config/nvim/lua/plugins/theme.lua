-- Follow the current Omarchy theme when running on an Omarchy machine.
--
-- Omarchy regenerates this file whenever the theme changes, so loading it at
-- runtime keeps nvim in sync with the rest of the desktop. This used to be a
-- symlink, but ~/.config/nvim is itself a stow symlink into ~/dotfiles, so a
-- relative link resolved against the wrong directory and silently dangled.
--
-- On macOS and Ubuntu there is no Omarchy theme, so this returns an empty spec
-- and LazyVim's default colorscheme applies.
local theme = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")

if vim.fn.filereadable(theme) == 1 then
  return dofile(theme)
end

return {}
