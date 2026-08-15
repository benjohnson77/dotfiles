-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Laptop panel.
hl.monitor({ output = "eDP-1", mode = "1920x1200@60", position = "0x0", scale = 1 })

-- Ultrawide, placed to the right of the laptop panel.
hl.monitor({ output = "DP-1", mode = "3840x1600@84.97", position = "1920x0", scale = 1 })

-- Lid switch handling is built into Omarchy 4 (omarchy-system-lid-close /
-- omarchy-hyprland-monitor-clamshell), so the old bindl rules are no longer needed.

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
