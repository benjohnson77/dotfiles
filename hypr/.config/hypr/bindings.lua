-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- ---------------------------------------------------------------------------
-- Personal app bindings, restored from the pre-Quattro ~/.config/hypr/hyprland.conf.
-- These use plain SUPER, so the colliding Omarchy defaults are unbound first.
-- Displaced defaults, if you ever want them back on another key:
--   SUPER + F      Full screen
--   SUPER + T      Toggle window floating/tiling
--   SUPER + S      Toggle scratchpad
--   SUPER + O      Pop window out (float & pin)
--   SUPER + C      Universal copy
--   SUPER + SLASH  Monitor scaling up
-- ---------------------------------------------------------------------------

hl.unbind("SUPER + F")
hl.unbind("SUPER + T")
hl.unbind("SUPER + S")
hl.unbind("SUPER + O")
hl.unbind("SUPER + C")
hl.unbind("SUPER + SLASH")

-- SUPER + RETURN is already Terminal by default, so it needs no override.
o.bind("SUPER + F", "File manager", { omarchy = "nautilus" })
o.bind("SUPER + B", "Browser", { omarchy = "browser" })
o.bind("SUPER + M", "Music", { omarchy = "spotify" })
o.bind("SUPER + N", "Editor", { omarchy = "editor" })
o.bind("SUPER + T", "Terminal", { omarchy = "terminal" })
o.bind("SUPER + D", "Docker", { tui = "lazydocker" })
o.bind("SUPER + S", "Slack", { launch = "slack", focus = "^slack$" })
o.bind("SUPER + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
o.bind("SUPER + SLASH", "Passwords", { launch = "bitwarden-desktop" })

-- Web apps. (SUPER + SHIFT + A is already Grok by default.)
o.bind("SUPER + A", "ChatGPT", { webapp = "https://chatgpt.com" })
o.bind("SUPER + Y", "YouTube", { webapp = "https://youtube.com/", focus = true })
o.bind("SUPER + E", "Email", { webapp = "https://mail.google.com/" })
o.bind("SUPER + C", "Calendar", { webapp = "https://calendar.google.com/calendar/u/0/r/week" })

-- Omarchy 4 ships HEY on these keys. Drop them since you're on Gmail/Google Calendar.
hl.unbind("SUPER + SHIFT + E")
hl.unbind("SUPER + SHIFT + ALT + E")
hl.unbind("SUPER + SHIFT + C")
